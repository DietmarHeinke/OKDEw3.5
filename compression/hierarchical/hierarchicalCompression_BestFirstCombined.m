function [pdf_cmprs , idxToref_out, augmented_pdf ]= hierarchicalCompression_BestFirstCombined( pdf, varargin )

type_cost = 1 ; % 1 means mean hellinger (th opt= 0.001, or 0.02), 2 means max dif in apost (th opt= 0.001 or 0.002)
use_mean_estimate = 0 ;
disableReclustering = 1 ; % lowdim reclustreing will not work because we don't split mixture in original dimensions
augmented_pdf = [] ;
idxToref_out = [] ;
ignoreSublayer = 0 ;
turn_off_splitting = 0 ;
testWeights = 0 ;
approximateCost = [] ;
otherClasses = [] ;
minNumberOfComponentsThreshold = 0 ;
debugForceCompress = [] ;
memoryLimit = [] ;
useWeightedHellinger = 1 ;
useLocalDistanceEvaluation = 0 ;
useMargHellingerCompression = 1 ;
useSMOprunning = 0 ;
% threshOnSplitMethods = inf ;
costFunction = 'hellinger'; %'hellinger, numberOfComponents, alpha_MDL'
costThreshold = 0.01^rows(pdf.Cov{1}) ;
numberOfSamples = [] ; 
% process arguments
args = varargin;
nargs = length(args);
for i = 1:2:nargs
    switch args{i}        
        case 'costFunction', costFunction = args{i+1} ;
        case 'costThreshold', costThreshold = args{i+1} ;          
        case 'useSMOprunning', useSMOprunning = args{i+1} ;       
        case 'useMargHellingerCompression', useMargHellingerCompression = args{i+1} ;
        case 'useLocalDistanceEvaluation', useLocalDistanceEvaluation = args{i+1} ; 
        case 'useWeightedHellinger', useWeightedHellinger = args{i+1} ;
        case 'memoryLimit', memoryLimit = args{i+1} ;
        case 'memorylimitUseNumComps', memorylimitUseNumComps = args{i+1} ;
        case 'debugForceCompress', debugForceCompress = args{i+1} ;
        case 'minNumberOfComponentsThreshold', minNumberOfComponentsThreshold = args{i+1} ;
        case 'otherClasses', otherClasses = args{i+1} ;
        case 'approximateCost', approximateCost = args{i+1} ;
        case 'turn_off_splitting', turn_off_splitting = args{i+1} ;
    end
end

% verify if compression is allowed at all
if length(pdf.w) <= minNumberOfComponentsThreshold  
    pdf_cmprs = pdf ;
    augmented_pdf = pdf ;
    return ;
end

useVbw_tmp = pdf.smod.useVbw ;

% are we using discriminative compression?
if ~isempty(otherClasses)  
    % precalculate statistics for compression
 
    if use_mean_estimate == 0
        otherClasses.pdf.precalcStat = uCostModel( otherClasses.pdf, pdf, [], otherClasses.priors, approximateCost, pdf.Mu(:,1) ) ;
    end
    
    hellCostThreshold_for_split = costThreshold.thReconstructive;   
    
    % override the costThreshod with reconstructive
    costThreshold = costThreshold.thDiscriminative ;
else
    costThreshold = costThreshold.thReconstructive ;
    hellCostThreshold_for_split = costThreshold.thReconstructive ;
end




% if 1==1 %isempty(memoryLimit) %|| getHell ~= 0
    inPars.costFunction = costFunction ;
    inPars.costThreshold = hellCostThreshold_for_split  ;  
    inPars.numberOfSamples = numberOfSamples ;
    inPars.MDL_params = [] ;
    inPars.useMargHellingerCompression = useMargHellingerCompression ;
    inPars.useLocalDistanceEvaluation = useLocalDistanceEvaluation ;
    inPars.numberOfSamples = numberOfSamples ;
    inPars.costFunction = 'hellinger' ;
    inPars.useWeightedHellinger = 1 + 0*useWeightedHellinger ;
    inPars.approximateCost = approximateCost ;
    beforeSplits = length(pdf.w) ;
    inPars.type_cost = type_cost ;
    if turn_off_splitting == 0
        pdf = executeSplitComponents( pdf, inPars, otherClasses, use_mean_estimate ) ;       
    else
    
%         ignoreSublayer = 1 ;
%         pdf.smod.H  = 0 ;
%  !!!!!!!!!!!!!!!!!!!!!!!!!!!!1 for dAMKDE this should be
%  enabled!!!!!!!!!!!!!!!!!!!!!11!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    end
% end
 augmented_pdf = [] ; % pdf ; 


if  ~isempty(otherClasses) && (abs(beforeSplits - length(pdf.w)) > 0)
    otherClasses.pdf.precalcStat = [] ;
    % precalculate statistics for compression
    otherClasses.pdf.precalcStat = uCostModel( otherClasses.pdf, pdf, [], otherClasses.priors, approximateCost, type_cost ) ;
end



MDL_params.Mcomps = inf ;
if ~isempty(memoryLimit) 
    if isinf(memoryLimit) && memorylimitUseNumComps == 0
        
    else        
        costThreshold = 0.0 ;
        if memorylimitUseNumComps == 0
            M_entire = getMemoryModel( pdf ) ;
            
            M_free = memoryLimit - M_entire ;
            d = size(pdf.Mu,1) ;
            N_spc = M_free/( ((d^2-d)/2 +d +1)*2 ) ;
            MDL_params.Mcomps = floor(max([1,length(pdf.w) + N_spc])) ;
        else
            MDL_params.Mcomps = memorylimitUseNumComps ;
        end
    end
end

if useSMOprunning == 1    
    pdf = pruneMixtureNoteSingletons( pdf ) ;   
end
 
% initialize compressed
% approximate using a single pdf
[new_mu, new_Cov, w_out] = momentMatchPdf(pdf.Mu, pdf.Cov, pdf.w) ;

pdf_cmprs.Mu = new_mu ;
pdf_cmprs.Cov = {new_Cov} ;
pdf_cmprs.w = w_out ;
% Hell = internalHellingerJointSupportnD( pdf_cmprs, pdf, useWeightedHellinger ) ;


if use_mean_estimate == 0
 Hell = uCostModel( otherClasses.pdf, pdf, pdf_cmprs, otherClasses.priors, approximateCost, pdf_cmprs.Mu, type_cost ) ;
else
 Hell = uCostModel_mode( otherClasses.pdf, pdf, pdf_cmprs, otherClasses.priors, approximateCost, pdf_cmprs  ) ;
end
 
cmp_data.idxToref = {[1:length(pdf.w)]} ;
cmp_data.hells = [Hell] ;
cmp_data.cantbrake = [0] ;


% if debug activated and compressed components selected
if ~isempty(debugForceCompress)
    sub_pdf = extractSubMixture( pdf, debugForceCompress, ignoreSublayer ) ;
    [new_mu, new_Cov, w_out] = momentMatchPdf(sub_pdf.Mu, sub_pdf.Cov, sub_pdf.w) ;
  
    pdf_cmprs.Mu = new_mu ;
    pdf_cmprs.Cov = {new_Cov} ;
    pdf_cmprs.w = w_out ;
    
   I = ones(1,length(pdf.w)) ;
   I(debugForceCompress) = 0 ;
   id_remain = find(I) ;
   
   sub_pdf = extractSubMixture( pdf, id_remain, ignoreSublayer ) ;
    
   pdf_cmprs = mergeDistributions( pdf_cmprs, sub_pdf, [1,1]  ) ;
   cmp_data.idxToref = { debugForceCompress, id_remain } ;
end


% loop while optimal clustering not reached
while length(pdf.w) >= minNumberOfComponentsThreshold  && isempty(debugForceCompress)
    [val, i_sel] = max(cmp_data.hells) ;
    if val <= costThreshold && minNumberOfComponentsThreshold <= length(cmp_data.idxToref)
       break ; 
    end
    
    % split selected component
    refbrake = cmp_data.cantbrake(i_sel);
    if refbrake == 2 
        cmp_data.hells(i_sel) = 0 ;
    end
    refidxs = cmp_data.idxToref{i_sel} ;
    sub_pdf = extractSubMixture( pdf, refidxs ) ;
    pdf0.Mu = pdf_cmprs.Mu(:,i_sel) ; 
    pdf0.Cov = pdf_cmprs.Cov(i_sel) ; 
    pdf0.w = pdf_cmprs.w(i_sel) ;  
    [pdf_split, K] = getTwoGaussianApproximation( sub_pdf, pdf0, refbrake ) ;
    
    if length(pdf_split.w) == 1 && length(K) > 1    
        cantbrake = 1 ;
        if refbrake == 1
           cantbrake = 2 ; 
        end
    else
        cantbrake = 0 ;
    end

    % replace component with the splitted, add another component,
    % modify indexes and calculate Hellinger errors
    
    pdf_cmprs.Mu(:,i_sel) = pdf_split.Mu(:,1) ;
    pdf_cmprs.Cov(i_sel) = pdf_split.Cov(1) ;
    pdf_cmprs.w(i_sel) = pdf_split.w(1) ;
    cmp_data.cantbrake(i_sel) = cantbrake ;
               
    if length(pdf_split.w) > 1
        pdf_cmprs.Mu = horzcat(pdf_cmprs.Mu, pdf_split.Mu(:,2) ) ;
        pdf_cmprs.Cov = horzcat(pdf_cmprs.Cov, pdf_split.Cov(2) ) ;
        pdf_cmprs.w = horzcat(pdf_cmprs.w, pdf_split.w(2) ) ;
        cmp_data.cantbrake = horzcat(cmp_data.cantbrake, cantbrake) ;
    end
    
    cmp_data.idxToref{i_sel} = refidxs( K==1 ) ;
    if length(pdf_split.w) > 1 %length(sub_pdf.w)==1   ////length(pdf_split.w) > 1
        cmp_data.idxToref = horzcat( cmp_data.idxToref, refidxs( K==2 ) ) ;
    end
    
    app_pdf = extractSubMixture( pdf_cmprs, i_sel ) ;
%     sub_pdf = extractSubMixture( pdf, cmp_data.idxToref{i_sel} ) ;
    if length(pdf_split.w)==1 %length(sub_pdf.w)==1
        Hell1 = 0 ;
    else
%         Hell1 = internalHellingerJointSupportnD( app_pdf, sub_pdf, useWeightedHellinger ) ;
%         app_pdf.w = app_pdf.w/ sum(app_pdf.w) ;
%         sub_pdf.w = sub_pdf.w/ sum(sub_pdf.w) ;
        
        
        selection = ones(1,length(pdf.w)) ;        
        selection(cmp_data.idxToref{i_sel}) = 0 ;       
        selection = find(selection) ;
        pdf_sel = extractSubPdf( pdf , selection, ignoreSublayer ) ;  
        % recombine components into augmented pdf
        pdf_compr = mergeDistributions( pdf_sel, app_pdf, [1 1], testWeights ) ;

 if use_mean_estimate == 0       
        Hell1 = uCostModel( otherClasses.pdf, pdf, pdf_compr,  otherClasses.priors, approximateCost, app_pdf.Mu, type_cost ) ;  
 else
          Hell1 = uCostModel_mode( otherClasses.pdf, pdf, pdf_compr,  otherClasses.priors, approximateCost, pdf_compr ); %app_pdf.Mu ) ;
 end
    end
    cmp_data.hells(i_sel) = Hell1 ;
    
    
    if length(pdf_split.w) > 1
        id_last = length(pdf_cmprs.w) ;
        app_pdf = extractSubMixture( pdf_cmprs, id_last ) ;
      
%         try
%         sub_pdf = extractSubMixture( pdf, cmp_data.idxToref{id_last} ) ;
%         catch
%             sgg = 3 
%         end
        
        if length(sub_pdf.w)==1
            Hell2 = 0 ;
        else
%             Hell2 = internalHellingerJointSupportnD( app_pdf, sub_pdf, useWeightedHellinger ) ;
%                 app_pdf.w = app_pdf.w/ sum(app_pdf.w) ;
%                 sub_pdf.w = sub_pdf.w/ sum(sub_pdf.w) ;


    selection = ones(1,length(pdf.w)) ;        
        selection(cmp_data.idxToref{id_last}) = 0 ;       
        selection = find(selection) ;   
        pdf_sel = extractSubPdf( pdf , selection, ignoreSublayer ) ;
        % recombine components into augmented pdf
        pdf_compr = mergeDistributions( pdf_sel, app_pdf, [1 1], testWeights ) ;

 if use_mean_estimate == 0       
        Hell2 = uCostModel( otherClasses.pdf, pdf, pdf_compr, otherClasses.priors, approximateCost, app_pdf.Mu, type_cost ) ;
 else
        Hell2 = uCostModel_mode( otherClasses.pdf, pdf, pdf_compr,  otherClasses.priors, approximateCost, pdf_compr) ; %app_pdf.Mu ) ;
 end
%                 Hell2 = uCostModel( otherClasses.pdf, app_pdf, sub_pdf,  otherClasses.priors, approximateCost ) ;
        end
        cmp_data.hells  = horzcat( cmp_data.hells, Hell2) ;
    end        
 
    % break if maximum number of components has been reached
    if MDL_params.Mcomps <= length(pdf_cmprs.w)
        break ;
    end
end

% prepare sublayers, etc.
% pdf_cmprs.suffStat.A = {} ;
% pdf_cmprs.suffStat.B = {} ;
% subLayer = [] ;
% for i = 1 : length(pdf_cmprs.w) 
%    id_sel = cmp_data.idxToref{i} ; 
%    subLayer_t = combineSubLayersOf( pdf, id_sel ) ;
%    subLayer = horzcat(subLayer, subLayer_t) ;
%    
%    sub_pdf = extractSubPdf( pdf , id_sel ) ;    
%    suffStat = calculateSuffStatOfMergedComps( sub_pdf ) ; 
%    
%    pdf_cmprs.suffStat.A = horzcat(pdf_cmprs.suffStat.A, suffStat.A{1}) ;
%    pdf_cmprs.suffStat.B = horzcat(pdf_cmprs.suffStat.B, suffStat.B{1}) ;    
% end
% pdf_cmprs.suffStat.subLayer = subLayer ; 

pdf_cmprs.smod.ps.Cov = {} ;
q = [] ;
if ignoreSublayer ~= 1
    for i = 1 : length(pdf_cmprs.w)
        id_sel = cmp_data.idxToref{i} ;
        [pdf_out, new_Cov] = combineSubLayersOf( pdf.smod.q(id_sel), ...
            pdf.w(id_sel), ...
            pdf.smod.H /2 ) ; %pdf_cmprs.Cov{i}/(length(id_sel))^2 ) ;
        q = horzcat(q, pdf_out) ;
        pdf_cmprs.smod.ps.Cov = horzcat(pdf_cmprs.smod.ps.Cov, new_Cov) ;
    end
end
pdf_cmprs.smod.q = q ;
pdf_cmprs.smod.H = pdf.smod.H ;
pdf_cmprs.smod.useVbw = useVbw_tmp;

if disableReclustering == 0
    if nargout > 1
        idxToref_out = cmp_data.idxToref ;
    end
else
    augmented_pdf = [] ;
    idxToref_out = [] ;
end

    
% ----------------------------------------------------------------------- %
function [pdf_out, new_Cov] = combineSubLayersOf( q_set, w, H ) %pdf, idx_src_cmps ) 
% merge sublayers
q_pdf.Mu = [] ;
q_pdf.Cov = {} ;
q_pdf.w = [] ;
for i = 1 : length(q_set)
   q_pdf.Mu = [ q_pdf.Mu, q_set(i).Mu ] ;
   q_pdf.Cov = horzcat(q_pdf.Cov, q_set(i).Cov) ;
   q_pdf.w = [q_pdf.w, q_set(i).w*w(i)] ;
end

q_pdf.w = q_pdf.w / sum(q_pdf.w) ;
pdf_out = mergeSampleModelClustering( q_pdf, H*0.5^2 ) ;
[new_mu, new_Cov, w_out] = momentMatchPdf(pdf_out.Mu, pdf_out.Cov, pdf_out.w) ;

% % % ----------------------------------------------------------------------- % 
% % function [H, sigmaPointsOut] = internalHellingerJointSupportnD( pdf1, pdf2, useWeighted )
% % 
% % if nargin < 2
% %     useWeighted = 0 ;
% % end
% % if useWeighted == 0
% %         pdf1.w = pdf1.w / sum(pdf1.w) ;
% %         pdf2.w = pdf2.w / sum(pdf2.w) ;
% % end
% % % warning('Turned off weight normalization in internalHellingerJointSupport!') ;
% % 
% % if ~isfield(pdf1,'sigmaPoints')
% %     MaxV = 3 ; 
% %     [X1, sigPointsPerComponent, sp_w1, k1 ] = getAllSigmaPointsOnMixture( pdf1, MaxV ) ;
% % else
% %     X1 = pdf1.sigmaPoints.X ;
% %     sigPointsPerComponent = pdf1.sigmaPoints.sigPointsPerComponent ;
% %     sp_w1 = pdf1.sigmaPoints.w ;
% %     k1 = pdf1.sigmaPoints.k ;
% % end
% % 
% % if ~isfield(pdf2,'sigmaPoints')
% %     MaxV = 3 ;
% %     [X2, sigPointsPerComponent, sp_w2, k2 ] = getAllSigmaPointsOnMixture( pdf2, MaxV ) ;
% % else
% %     X2 = pdf2.sigmaPoints.X ;
% %     sigPointsPerComponent = pdf2.sigmaPoints.sigPointsPerComponent ;
% %     sp_w2 = pdf2.sigmaPoints.w ;
% %     k2 = pdf2.sigmaPoints.k ;
% % end
% %     
% % f0 = mergeDistributions( pdf1, pdf2, [0.5 0.5], 0 ) ;
% % f0.w = f0.w / sum(f0.w) ;
% % 
% % X = [X1, X2] ;
% % w = sp_w1 ;
% % W = repmat(f0.w,sigPointsPerComponent,1) ;
% % W = reshape(W,1,length(f0.w)*sigPointsPerComponent) ;
% % w2 = repmat(w,1,length(f0.w)) ;
% % W = W.*w2 ;
% % 
% % pdf_f1 = evaluatePointsUnderPdf(pdf1, X) ;
% % pdf_f2 = evaluatePointsUnderPdf(pdf2, X) ;
% %  
% % pdf_f1 = pdf_f1.*(pdf_f1 > 0) ;
% % pdf_f2 = pdf_f2.*(pdf_f2 > 0) ;
% % 
% % pdf_f0 = evaluatePointsUnderPdf( f0, X ) ;
% %  
% % g = (sqrt(pdf_f1)- sqrt(pdf_f2)).^2 ;
% %  
% % H = sqrt(abs(sum(W.*g./pdf_f0)/2)) ;  
% % 
% % % for debugging
% % % H = uHellingerJointSupport2_ND( pdf1, pdf2,...
% % %                                 'useMarginals', 0 ) ; 
% % %  
% % 
% % 
% % sigmaPointsOut = [] ;
% % if nargout == 2
% %     sigmaPointsOut.pdf1.sigmaPoints.X = X1 ;
% %     sigmaPointsOut.pdf1.sigmaPoints.sigPointsPerComponent = sigPointsPerComponent ;
% %     sigmaPointsOut.pdf1.sigmaPoints.w = sp_w1 ;
% %     sigmaPointsOut.pdf1.sigmaPoints.k = k1 ;
% %     sigmaPointsOut.pdf1.sigmaPoints.X = X2 ;
% %     sigmaPointsOut.pdf1.sigmaPoints.sigPointsPerComponent = sigPointsPerComponent ;
% %     sigmaPointsOut.pdf1.sigmaPoints.w = sp_w2 ;
% %     sigmaPointsOut.pdf1.sigmaPoints.k = k2 ;
% % end



