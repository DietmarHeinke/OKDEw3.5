%%
% Originally a part of: Maggot (developed within EU project CogX)
% Author: Matej Kristan, 2009 (matej.kristan@fri.uni-lj.si; http://vicos.fri.uni-lj.si/matejk/)
% Last revised: 2009
%
% Added GPU use for vert large 
%%
function [ p, model ] = evaluatePointsUnderPdf(model, X, input_minerr, diag_noise)
% % % % % % % % % % % % % % % % % % % % % % %
% model ... gaussian mixture model
% X     ... points
% % % % % % % % % % % % % % % % % % % % % % % 
 
minerr = [] ;
if nargin == 3
    minerr = input_minerr ;
end
if nargin < 4
    diag_noise = [] ;
end

% [ p, model ] = normmixpdf( model, X, minerr ) ;

% global isGpu;
isGpu = 0;
% check if GPU should be used instead.
cpu = 1;
if isGpu
    cov = cell2mat(model.Cov);
    if size(cov,2) == size(model.w,2) && length(X) > 1000
        % Create data copies in GPU.
        d_model = struct();
        d_model.Cov = gpuArray(cov);
        d_model.Mu = gpuArray(model.Mu);
        d_model.w = gpuArray(model.w);
        d_X = gpuArray (X);
        d_diag_noise = gpuArray (diag_noise);
        
        [ d_p, d_model ] = normmixpdf_slow_gpu(d_model, d_X, d_diag_noise) ;
        
        p = gather (d_p);
        model = gather (d_model);
        
        cpu = 0;
        
%         reset(gpuDevice);
    end
end

if cpu
    [ p, model ] = normmixpdf_slow( model, X, diag_noise ) ;
end

% p = zeros(1,size(X,2)) ;
% for i = 1 :  length(model.w)
%     p = p + model.w(i)*normpdf(X,model.Mu(:,i),[], model.Cov{i}) ; 
% end
     
if nargout == 1 
    model = [] ; 
end