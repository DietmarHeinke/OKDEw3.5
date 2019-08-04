function demo_oKDE()
% 
% Demo of the oKDE [1] and unlearning [3]
% [1] Kristan Matej, Leonardis Ales and Skocaj Danijel, "Multivariate Online Kernel Density Estimation with Gaussian Kernels", 
% Pattern Recognition, 2011.
% [3] Matej Kristan, Danijel Sko�aj, and Ale� Leonardis, "Online Kernel Density Estimation For Interactive Learning"
% Image and Vision Computing, 2009
%
% Author: Matej Kristan, 2013.

% install the oKDE
pth = './supp/' ; rmpath(pth) ; addpath(pth) ;
installEntireMaggot3() ; 
 
demo_to_show = 8 ; % 1 2 3 4 5 6 7 8 9

switch(demo_to_show)
    case 1
        % disp('----- Demonstating 1D learning example ---------') ;
        demo1Destimation() ;
    case 2
        % disp('----- Demonstating 2D estimation ---------') ;
        demo2Destimation() ;
    case 3
        % disp('----- Demonstating weighted 1D learning example ---------') ;
        demo1D_weightedestimation() ;
    case 4
        % disp('----- Demonstating 1D learning and unlearning example ---------') ;
        demonstrateLearninigUnlearning1D() ;
    case 5
        % disp('----- Demonstating likelihood evaluation and marginalization ---------') ;
        demoEvaluations() ;
        %
    case 6
        % disp('------ Demonstrating nonstationary distribution --------');
        estimateNonstat() ;
    case 7
        % disp('------ Demonstrating 3D distribution and visualization --------');
        demo3Destimation() ;
    case 8
        % disp('------ Demonstrating 3D distribution and visualization with postprocessing --------');
        demo3DestimationPostProcessing() ;
    case 9
        % disp('------ Mode analysis of the estimated density --------');
        demoModeDetection() ;
%     case 9
%         EvalOptBWScale() ;
%             EvalOptBWScaleFullTest() ;
end
 
% ----------------------------------------------------------------------- %
function estimateNonstat()

N_max = 8000 ;
N_effLim = 1000 ;
morphfact = 1 - 1/N_effLim ;
MaW1 =  3 ; MyDi1 = 0 ;
MaW2 = 0*6 ; MyDi2 = 9+0*6 ;    

% generate intial samples from first mixture
[x_init, pdf] = generateValuesPdf( 3, 'MaWa',MaW1, 'MyDi', MyDi1); 
[x1, pdf1] = generateValuesPdf( 50000,'MaWa',MaW1, 'MyDi', MyDi1); 
[x2, pdf2] = generateValuesPdf( 50000,'MaWa',MaW2, 'MyDi', MyDi2); 
 
apply_EM_updates = 1 ; % apply approximate updates for fast operation

% initialize the oKDE
kde = executeOperatorIKDE( [], 'input_data', x_init,'add_input','kde_w_attenuation', morphfact, 'apply_EM_updates', apply_EM_updates  ) ; 

w_mix1 = 1 ;
for i = 1 : N_max 
    if i > 1000
       w_mix1 = w_mix1*morphfact ;         
    end
    
    % get pdf and the sampled datapoint
    [x, pdf_ref] = generateNonstatDistributionsAndVals(MaW1, MaW2, MyDi1, MyDi2, x1, x2, w_mix1, i) ;
    
    % update oKDE
    tic 
    kde = executeOperatorIKDE( kde, 'input_data', x,'add_input'  ) ;
    toc
    
    % plot results
    figure(1) ; clf ; 
    showDecomposedUniNormMixPdf(pdf_ref, 'decompose', 0, 'linTypeSum','--g' ) ;
    hold on ;
    executeOperatorIKDE( kde, 'showKDE','showkdecolor', 'b' ) ;
    plot(x, x*0, 'o', 'MarkerSize',10, 'MarkerEdgeColor','b', 'MarkerFaceColor','w', 'LineWidth',2 ) ;  
    a = axis ; axis([-3.5, 3,0, a(4)]) ;
    msg = sprintf('Observed %d, Number of components %d, N_{eff}=%1.3g, w_{mix1}=%1.3g', i, length(kde.pdf.w), kde.ikdeParams.N_eff, w_mix1 ) ;
    title(msg) ;    
end

% ----------------------------------------------------------------------- %
function demo2Destimation()

% generate some datapoints 
N = 10000 ;
Dth = 0.02 ; % allowed Hellinger distance error in compression
N_init = 3 ;
modd = 5 ;
dat = generateSpiral(N,[]) ;

apply_EM_updates = 1 ; % apply approximate updates for fast operation

kde = executeOperatorIKDE( [], 'input_data', dat(:,1:N_init),'add_input' );
kde = executeOperatorIKDE( kde, 'compressionClusterThresh', Dth, 'apply_EM_updates', apply_EM_updates ) ;
for i = N_init+1 : size(dat,2) 
    tic
    kde = executeOperatorIKDE( kde, 'input_data', dat(:,i), 'add_input'  ) ;
    toc
    if mod(i,modd)==0 
        figure(1) ; clf ;
        hold on ;
        plot(dat(1,1:i), dat(2,1:i), '.', 'MarkerEdgeColor', [1, 0.4, 0.4]) ;
        executeOperatorIKDE( kde, 'showKDE','showkdecolor', 'b' ) ;
        msg = sprintf('Samples: %d ,Comps: %d \n', i , length(kde.pdf.w) ) ; 
        title(msg) ; axis equal ; axis([-13, 13, -13, 13])
    end
end 
 
% ----------------------------------------------------------------------- %
function demoEvaluations()

disp('Estimate oKDE from 30 samples') ;
Nl = 30 ; 
dat = rand(3,Nl) ;
kde = executeOperatorIKDE( [], 'input_data', dat,'add_input' ) ;

x = rand(3,5) ;
disp('Evaluatate likelihood of  some points under the oKDE') ;
selectSubDimensions = [] ;
res = executeOperatorIKDE( kde, 'input_data', x, 'evalPdfOnData', 'selectSubDimensions', selectSubDimensions ) ;
res.subRegularized
res.evalpdf

disp('Evaluatate likelihood of some points under the oKDE by ignoring the second dimension') ;
selectSubDimensions = [1 3] ;
res = executeOperatorIKDE( kde, 'input_data', x, 'evalPdfOnData', 'selectSubDimensions', selectSubDimensions ) ;
res.subRegularized
res.evalpdf

disp('Evaluatate typicality of some points under the oKDE by ignoring the second dimension') ;
disp('Typicality is defined as the ratio between the probability of a point under the pdf and') ;
disp('the probability of the most probable point (maximum of pdf).') ;
selectSubDimensions = [1 3 ] ;
res = executeOperatorIKDE( kde, 'input_data', x, 'evalTypOnData', 'selectSubDimensions', selectSubDimensions ) ;
res.subRegularized
res.evaltyp
kde = res.kde ;

% ----------------------------------------------------------------------- %
function demonstrateLearninigUnlearning1D()

switchSelectionSeeds = 0 ;    
    
% generate data for the model
N = 100 ; N_init = 5 ;
[x, pdf] = generateValuesPdf( N, 'MaWa',0, 'MyDi',6 ) ; 
x_init = x(:,1:N_init) ;
x = x(:,N_init+1:length(x)) ;

% initialize the KDE
kde = executeOperatorIKDE( [], 'input_data', x_init, 'add_input', 'switchSelectionSeeds', switchSelectionSeeds ) ;
t1 = 0 ;
% incrementally add data and show result
for i = 1 : size(x,2)
    % add a data point
    tic
    kde = executeOperatorIKDE( kde, 'input_data', x(:,i), 'add_input' ) ; 
    t1 = t1 + toc ;
 
    % draw reference, model and estimate
    figure(1); clf ; subplot(1,2,1) ;
    showDecomposedUniNormMixPdf(pdf, 'decompose', 0, 'linTypeSum', '--g') ; hold on ; 
    executeOperatorIKDE( kde, 'showKDE', 'showkdecolor', 'b' ) ;
    plot(x(1:i),zeros(1,i),'r*') ;
end
msg = sprintf('Average time per adition: %1.5g s', t1/size(x,2)) ; disp( msg ) ;

% select negative points for unlearning
x_neg = rand(1,20)*1 + 0.5 ;
plot(x_neg, x_neg*0, 'b+') ; plot(x_neg, x_neg*0, 'mO') ;
title('Learning/unlearning using points only')


% unlearn with points
tic
kde_unlwpts = executeOperatorIKDE( kde, 'input_data', x_neg,'unlearn_with_input' ) ;
t1 = toc ; msg = sprintf('Time for unlearning using samples: %1.5g s', t1 ) ; disp( msg ) ;

% show result
showDecomposedUniNormMixPdf(pdf, 'decompose', 0, 'linTypeSum', '--g') ; hold on ; 
drawDistributionGMM( 'pdf', kde.pdf, 'decompose', 0, 'color', 'b' ) ;
drawDistributionGMM( 'pdf', kde_unlwpts.pdf, 'decompose', 0, 'color', 'r' ) ;
plot(x_neg, x_neg*0, 'mO') ;

% end

% Example 2: unlearning with another kde
% initialize the negative KDE
 kde_neg = executeOperatorIKDE( [], 'input_data', x_neg, 'add_input' ) ;
% unlearn with kde
tic ;
kde_unlwkde = executeOperatorIKDE( kde, 'input_data', kde_neg, 'unlearn_with_input' ) ;
t1 = toc ; msg = sprintf('Time for unlearning using negative kde: %1.5g s', t1 ) ; disp( msg ) ; 

figure(2) ; clf ;
showDecomposedUniNormMixPdf(pdf, 'decompose', 0, 'linTypeSum', '--g') ; hold on ; 
drawDistributionGMM( 'pdf', kde.pdf, 'decompose', 0, 'color', 'b' ) ;
drawDistributionGMM( 'pdf', kde_neg.pdf, 'decompose', 0, 'color', 'c' ) ;
drawDistributionGMM( 'pdf', kde_unlwkde.pdf, 'decompose', 0, 'color', 'r' ) ;
title('Unlearning using kdes')
 
figure(1) ;
% incrementally add data and show result
for i = 1 : size(x,2)
    % add a data point
    tic
    kde_unlwpts = executeOperatorIKDE( kde_unlwpts, 'input_data', x(:,i), 'add_input' ) ; 
    t1 = t1 + toc ;
 
    % draw reference, model and estimate
    subplot(1,2,2) ; hold off ;
    showDecomposedUniNormMixPdf(pdf, 'decompose', 0, 'linTypeSum', '--g') ; hold on ; 
    executeOperatorIKDE( kde_unlwpts, 'showKDE', 'showkdecolor', 'b' ) ; drawnow ;
    plot(x(1:i),zeros(1,i),'r*') ;
end
title('Unlearnt KDE with additional learning')
 

% ----------------------------------------------------------------------- %
function demo1Destimation()
% Contents:
% Samples are generated from a distribution and added on at a time to the oKDE.
    
% generate some datapoints 
N = 1000 ;
Dth = 0.02 ; % allowed Hellinger distance error in compression
modd = 5 ;
 
MaW1 = 0 ; 
MyDi1 = 5 ;
[dat, pdf_ref] = generateValuesPdf( N,'MaWa',MaW1, 'MyDi', MyDi1) ;
 

% plot without EM approximate updates
kde = executeOperatorIKDE( [], 'input_data', dat(:,1:3),'add_input' );
kde = executeOperatorIKDE( kde, 'compressionClusterThresh', Dth, 'apply_EM_updates', 0 ) ;
for i = 4 : size(dat,2) 
    tic
    kde = executeOperatorIKDE( kde, 'input_data', dat(:,i), 'add_input'  ) ;
    toc
    if mod(i,modd)==0 
        figure(1) ; clf ;
        hold on ;
        showDecomposedUniNormMixPdf(pdf_ref, 'decompose', 0, 'linTypeSum','--g' ) ;
        plot(dat(1:i), 0*dat(1:i), '.', 'MarkerEdgeColor', [1, 0.4, 0.4]) ;
        executeOperatorIKDE( kde, 'showKDE','showkdecolor', 'b' ) ;
        plot(dat(i), dat(i)*0, 'o', 'MarkerSize',10, 'MarkerEdgeColor','b', 'MarkerFaceColor','w', 'LineWidth',2 ) ;         
        msg = sprintf('Samples: %d ,Comps: %d', i , length(kde.pdf.w)) ; 
        title(msg) ; 
    end
end

figure(1) ; clf ;
hold on ;
showDecomposedUniNormMixPdf(pdf_ref, 'decompose', 0, 'linTypeSum','--g' ) ;
plot(dat(1:i), 0*dat(1:i), '.', 'MarkerEdgeColor', [1, 0.4, 0.4]) ;
executeOperatorIKDE( kde, 'showKDE','showkdecolor', 'b' ) ;
plot(dat(i), dat(i)*0, 'o', 'MarkerSize',10, 'MarkerEdgeColor','b', 'MarkerFaceColor','w', 'LineWidth',2 ) ;
msg = sprintf('Samples: %d ,Comps: %d', i , length(kde.pdf.w)) ;
title(msg) ;


% plot without EM approximate updates
kde = executeOperatorIKDE( [], 'input_data', dat(:,1:3),'add_input' );
kde = executeOperatorIKDE( kde, 'compressionClusterThresh', Dth, 'apply_EM_updates', 1 ) ;
for i = 4 : size(dat,2) 
    tic
    kde = executeOperatorIKDE( kde, 'input_data', dat(:,i), 'add_input'  ) ;
    toc
    if mod(i,modd)==0 
        figure(2) ; clf ;
        hold on ;
        showDecomposedUniNormMixPdf(pdf_ref, 'decompose', 0, 'linTypeSum','--g' ) ;
        plot(dat(1:i), 0*dat(1:i), '.', 'MarkerEdgeColor', [1, 0.4, 0.4]) ;
        executeOperatorIKDE( kde, 'showKDE','showkdecolor', 'b' ) ;
        plot(dat(i), dat(i)*0, 'o', 'MarkerSize',10, 'MarkerEdgeColor','b', 'MarkerFaceColor','w', 'LineWidth',2 ) ;         
        msg = sprintf('Samples: %d ,Comps: %d', i , length(kde.pdf.w)) ; 
        title(msg) ; 
    end
end

figure(2) ; clf ;
hold on ;
showDecomposedUniNormMixPdf(pdf_ref, 'decompose', 0, 'linTypeSum','--g' ) ;
plot(dat(1:i), 0*dat(1:i), '.', 'MarkerEdgeColor', [1, 0.4, 0.4]) ;
executeOperatorIKDE( kde, 'showKDE','showkdecolor', 'b' ) ;
plot(dat(i), dat(i)*0, 'o', 'MarkerSize',10, 'MarkerEdgeColor','b', 'MarkerFaceColor','w', 'LineWidth',2 ) ;
msg = sprintf('Samples: %d ,Comps: %d', i , length(kde.pdf.w)) ;
title(msg) ;

% ----------------------------------------------------------------------- %
function demo1D_weightedestimation()
% Contents:
% Samples are generated from a distribution and noise is added to the
% samples. Each sample is weighted w.r.t. its typicality. This demonstrates
% how to use different a priori weights for each input sample.
    
% generate some datapoints 
N = 1000 ;
Dth = 0.02 ; % allowed Hellinger distance error in compression
modd = 5 ;
sensitivity = 0.9 ; % ~ 0.5 will focus on dominant modes; ~2 will weight everything approximately the same

MaW1 = 0 ; 
MyDi1 = 5 ;
[dat, pdf_ref] = generateValuesPdf( N,'MaWa',MaW1, 'MyDi', MyDi1) ;
sig = 0.3 ; % standard deviation of the additive noise

kde = executeOperatorIKDE( [], 'input_data', dat(:,1:3),'add_input' );
kde = executeOperatorIKDE( kde, 'compressionClusterThresh', Dth ) ;
for i = 4 : size(dat,2) 
    
    % add noise to the data-point 
    dat(:,i) = dat(:,i) + randn()*sig ;
    
    % evaluate typicality of data-point under current KDE
    res = executeOperatorIKDE( kde, 'input_data', dat(:,i), 'evalTypOnData'  ) ;
    
    % set the data-point weigth to its typicality
    obs_relative_weights = exp(-0.5*((1-res.evaltyp)/sensitivity).^2)  ;
    tic
    kde = executeOperatorIKDE( kde, 'input_data', dat(:,i), 'add_input', 'obs_relative_weights', obs_relative_weights  ) ;
    toc
    if mod(i,modd)==0 
        figure(1) ; clf ;
        hold on ;
        showDecomposedUniNormMixPdf(pdf_ref, 'decompose', 0, 'linTypeSum','--g' ) ;
        plot(dat(1:i), 0*dat(1:i), '.', 'MarkerEdgeColor', [1, 0.4, 0.4]) ;
        executeOperatorIKDE( kde, 'showKDE','showkdecolor', 'b' ) ;
        plot(dat(i), dat(i)*0, 'o', 'MarkerSize',10, 'MarkerEdgeColor','b', 'MarkerFaceColor','w', 'LineWidth',2 ) ;         
        msg = sprintf('Samples: %d ,Comps: %d \n, Distortion: %1.3g', i , length(kde.pdf.w),sig ) ; 
        title(msg) ; 
    end
end


% ----------------------------------------------------------------------- %
 function x = generateSpiral(N,t0)

if nargin < 3
    genIm = 0 ;
end

a = 1 ;
b = 1 ;
% t0 = [] ;
if nargin < 2 || isempty(t0) %||  length(t0) < 2
    theta = rand(1,N)*10 ; %25 ;
else
    theta = 10*t0 ;
end

sig = 0.9 ; %1 ;%0.1 ;
r = a + b*theta ;
y = sin(theta).*r + randn(1,N)*sig ; 
x = cos(theta).*r + randn(1,N)*sig ;
x = [x;y] ;


% ----------------------------------------------------------------------- %
function [x, pdf_ref] = generateNonstatDistributionsAndVals(MaW1, MaW2, MyDi1, MyDi2, x1, x2, w_mix1, i)         
    [x0, pdf_ref1] = generateValuesPdf( 1, 'MaWa',MaW1, 'MyDi', MyDi1) ;
    [x0, pdf_ref2] = generateValuesPdf( 1, 'MaWa',MaW2, 'MyDi', MyDi2) ;
    if ~isfield(pdf_ref2,'uni')
        pdf_ref2.uni.mu=[] ;pdf_ref2.uni.widths=[] ; pdf_ref2.uni.weights=[] ;
    end
    if ~isfield(pdf_ref1,'uni')
        pdf_ref1.uni.mu=[] ;pdf_ref1.uni.widths=[] ; pdf_ref1.uni.weights=[] ;
    end
    
    pdf_ref.uni.mu = [pdf_ref1.uni.mu, pdf_ref2.uni.mu] ;
    pdf_ref.uni.widths = [pdf_ref1.uni.widths, pdf_ref2.uni.widths] ;
    pdf_ref.uni.weights = [pdf_ref1.uni.weights*w_mix1, pdf_ref2.uni.weights*(1-w_mix1)] ;
    pdf_ref.norm.mu = [pdf_ref1.norm.mu, pdf_ref2.norm.mu] ;
    pdf_ref.norm.weights = [pdf_ref1.norm.weights*w_mix1, pdf_ref2.norm.weights*(1-w_mix1)] ;
    pdf_ref.norm.covariances = vertcat(pdf_ref1.norm.covariances, pdf_ref2.norm.covariances ) ;
    
    
    cs = cumsum([w_mix1 (1-w_mix1)]) ;
    if rand(1) < cs(1)
         x = x1(i) ;
    else
         x = x2(i) ;
    end
    
% ----------------------------------------------------------------------- %
function demo3Destimation()
% Contents:
% Samples are generated from 3D mixture model.
% The demo displays the reference 3D model and its current estimate. It
% then visualizes the resulting model as projections to pairs of axes --
% this is just a marginalization of the pdf and visualization of the
% resulting 2D model.
    
% to get a better feel of the smoothing, try running this with Dth = 0.02 ; and Dth = 0.05 ;    

% generate some datapoints 
N = 10000 ;
Dth = 0.02 ; % allowed Hellinger distance error in compression
apply_EM_updates = 1 ; % [ 1 0 ] whether to use the EM updates (a bit faster)
modd = 1000 ;
 
K = 6 ;
pdf_gen.Mu = rand(3,K)*10 ; pdf_gen.Cov = {} ;
for i = 1:K
    pdf_gen.Cov = horzcat(pdf_gen.Cov, 0.5+diag(rand(1,3)*2)) ;
end
pdf_gen.w = ones(1,K)/K ;

% sample data from the model
dat = sampleGaussianMixture( pdf_gen, N ) ; 

% initialize
kde = executeOperatorIKDE( [], 'input_data', dat(:,1:5),'add_input' );
kde = executeOperatorIKDE( kde, 'compressionClusterThresh', Dth, 'apply_EM_updates', apply_EM_updates ) ;
for i = 4 : size(dat,2) 
%     tic
    kde = executeOperatorIKDE( kde, 'input_data', dat(:,i), 'add_input'  ) ;
%     toc
    if mod(i,modd)==0 || i==size(dat,2)
        figure(1) ; clf ;
        subplot(1,2,1) ; hold on ;
        k.pdf = pdf_gen ; visualizeKDE('kde', k) ;
        title('reference distribution') ; axis equal ; axis tight ;  view([45 45]) ; 
        xlabel('x') ; ylabel('y') ; zlabel('z') ;
        subplot(1,2,2) ; hold on ;         
        plot3(dat(1, 1:i), dat(2, 1:i), dat(3, 1:i), 'c.') ;
        executeOperatorIKDE( kde, 'showKDE','showkdecolor', 'b' ) ;                     
        msg = sprintf('Samples: %d ,Comps: %d', i , length(kde.pdf.w)) ;         
        title(msg) ; axis equal ; axis tight ; view([45 45]) ;
        xlabel('x') ; ylabel('y') ; zlabel('z') ;
    end
end

% show a sequence of 2D projections -- this is simply achieved by
% marginalizing out the appropriate dimensions
visualize3D_kde_as_2D_projections( k, 2, 3 ) ;
visualize3D_kde_as_2D_projections( kde, 4, 5 ) ;
 
% --------------------------------------------------------------------- %
function demo3DestimationPostProcessing()

% Contents:
% Samples are generated from 3D mixture model.
% The demo displays the reference 3D model and its current estimate postprocessed by mean-shift. It
% then visualizes the resulting model as projections to pairs of axes --
% this is just a marginalization of the pdf and visualization of the
% resulting 2D model.
    
% to get a better feel of the smoothing, try running this with Dth = 0.02 ; and Dth = 0.05 ;    
close all ; pause(0.001) ;

% generate some datapoints 
N = 10000 ;
Dth = 0.02 ; % allowed Hellinger distance error in compression
apply_EM_updates = 1 ; % [ 1 0 ] whether to use the EM updates (a bit faster)
 
K = 6 ;
pdf_gen.Mu = rand(3,K)*10 ; pdf_gen.Cov = {} ;
for i = 1:K
    pdf_gen.Cov = horzcat(pdf_gen.Cov, 0.5+diag(rand(1,3)*2)) ;
end
pdf_gen.w = ones(1,K)/K ;

% sample data from the model
dat = sampleGaussianMixture( pdf_gen, N ) ; 

% initialize
kde = executeOperatorIKDE( [], 'input_data', dat(:,1:5),'add_input' );
kde = executeOperatorIKDE( kde, 'compressionClusterThresh', Dth, 'apply_EM_updates', apply_EM_updates ) ;
for i = 4 : size(dat,2) 
    kde = executeOperatorIKDE( kde, 'input_data', dat(:,i), 'add_input'  ) ; 
end

% post process by further compression
[clusters, modes_locations, modes_probs, pdf_out_moment_matched, ~ ] = ...
                                  detect_modes_and_approximate_by_l2_and_moment_match(kde.pdf) ;
kde_compressed_mm.pdf = pdf_out_moment_matched ;
 
 % visualize the distributions
 figure(1) ; clf ;
 subplot(1,3,1) ; hold on ;
 k.pdf = pdf_gen ; visualizeKDE('kde', k) ;
 title('reference distribution') ; axis equal ; axis tight ;  view([45 45]) ;
 xlabel('x') ; ylabel('y') ; zlabel('z') ;
 subplot(1,3,2) ; hold on ;
 plot3(dat(1, :), dat(2, :), dat(3, :), 'c.') ;
 executeOperatorIKDE( kde, 'showKDE','showkdecolor', 'b' ) ;
 msg = sprintf('Samples: %d ,Comps: %d', N , length(kde.pdf.w)) ;
 title(msg) ; axis equal ; axis tight ; view([45 45]) ;
 xlabel('x') ; ylabel('y') ; zlabel('z') ;
 subplot(1,3,3) ; hold on ;
 plot3(dat(1, :), dat(2, :), dat(3, :), 'c.') ;
 executeOperatorIKDE( kde_compressed_mm, 'showKDE','showkdecolor', 'b' ) ;
 msg = sprintf('Postprocessed kde (mm), Comps: %d', length(kde_compressed_mm.pdf.w)) ;
 title(msg) ; axis equal ; axis tight ; view([45 45]) ;
 xlabel('x') ; ylabel('y') ; zlabel('z') ;
                                             
                              
% show a sequence of 2D projections -- this is simply achieved by
% marginalizing out the appropriate dimensions
visualize3D_kde_as_2D_projections( k, 2, 3 ) ;
visualize3D_kde_as_2D_projections( kde, 4, 5 ) ;    
visualize3D_kde_as_2D_projections( kde_compressed_mm, 6, 7 ) ;       

% --------------------------------------------------------------------- %
function demoModeDetection()
% Contents:
% Mode detection on a Gaussian Mixture Model using Mean Shift
 
% Construct a random model
K = 6 ;
pdf_ref.Mu = rand(2,K) ; pdf_ref.Cov = {} ;
pdf_ref.Mu (:,1:3) = pdf_ref.Mu (:,1:3)*0.4 ;
pdf_ref.Mu (:,4:end) = pdf_ref.Mu (:,4:end)*5 ;
for i = 1:K
    pdf_ref.Cov = horzcat(pdf_ref.Cov, 0.5+diag(rand(1,2))) ;
end
pdf_ref.w = ones(1,K)/K ;
kde_ref.pdf = pdf_ref ;

% perform Mean Shift mode detection and approximate the clusters by two
% metods: Moment-matching and L2 norm (note that the resulting components will likely not have their modes at the
%          same location as the detected modes!).
[clusters, modes_locations, modes_probs, pdf_out_moment_matched, ~ ] = ...
                                  detect_modes_and_approximate_by_l2_and_moment_match(kde_ref.pdf) ;

% store the moment-mached approximation
kde_out_mm.pdf = pdf_out_moment_matched ;
% store the l2 approximation
% kde_out_l2.pdf = pdf_out_l2 ;

figure(1) ; clf ;
% plot the tabulated/analytic reference distribution
subplot(1,3,1) ; 
visualizeKDE('kde', kde_ref) ; axis equal ; axis tight ;
boundsIm = axis ; 
[A_ref, pts_xy, X_tck_xy, Y_tck_xy] = tabulate2D_gmm( kde_ref.pdf, boundsIm, 100 ) ; 
imagesc(X_tck_xy, Y_tck_xy, A_ref) ;  axis equal; axis tight;
hold on ; visualizeKDE('kde', kde_ref,'showkdecolor', 'k') ;
xlabel('x') ; ylabel('y') ;
title('Reference distribution') ; 

% Show detected modes on the distribution
subplot(1,3,2) ; 
imagesc(X_tck_xy, Y_tck_xy, A_ref) ; axis equal; axis tight; hold on ;
xlabel('x') ; ylabel('y') ;
plot(modes_locations(1,:),modes_locations(2,:),'O', 'MarkerFaceColor', [0.5 0.5 1], 'MarkerEdgeColor', 'k', 'LineWidth', 2) ;
for i = 1 : size(modes_locations,2)
    text( modes_locations(1,i)+0.2, modes_locations(2,i)-0.2, sprintf('%1.1g', modes_probs(i)) ) ;
end
title('Detected modes') ; 

% Show moment-matched approximation
subplot(1,3,3) ;  
[A_xy, pts_xy, X_tck_xy, Y_tck_xy] = tabulate2D_gmm( kde_out_mm.pdf, boundsIm, 100 ) ; 
imagesc(X_tck_xy, Y_tck_xy, A_xy) ;  axis equal; axis tight;
hold on ; visualizeKDE('kde', kde_out_mm,'showkdecolor', 'k') ;
xlabel('x') ; ylabel('y') ;
title('Mean shift clustered approximation') ; 

% % Show l2 approximation
% subplot(1,4,4) ;  
% [A_xy, pts_xy, X_tck_xy, Y_tck_xy] = tabulate2D_gmm( kde_out_l2.pdf, boundsIm, 100 ) ; 
% imagesc(X_tck_xy, Y_tck_xy, A_xy) ;  axis equal; axis tight;
% hold on ; visualizeKDE('kde', kde_out_l2,'showkdecolor', 'k') ;
% xlabel('x') ; ylabel('y') ;
% title('L_2 distance clustered approximation') ; 
  
% --------------------------------------------------------------------- %
% Debug  and some (internal) evaluation code 

function EvalOptBWScale()
% Contents:
% Samples are generated from 3D mixture model.
% The demo displays the reference 3D model and its current estimate. It
% then visualizes the resulting model as projections to pairs of axes --
% this is just a marginalization of the pdf and visualization of the
% resulting 2D model.
    
global scale_factor_bw_global ;
scale_factor_bw_global = 1 ;
% generate some datapoints 
N = 1009 ;
Dth = 0.05 ; % allowed Hellinger distance error in compression
apply_EM_updates = 0 ; % [ 1 0 ] whether to use the EM updates (a bit faster)
% modd = 500 ;
 
d_Reslt = {} ;
for i_dim = 1 : 1 : 10
    
    Reslt = {} ;
    for r_expr = 1 : 5 
        K = 3 ;
        pdf_gen.Mu = rand(i_dim,K)*15 ; pdf_gen.Cov = {} ;
        for i = 1:K
            pdf_gen.Cov = horzcat(pdf_gen.Cov, 0.5+diag(rand(1,i_dim)*2)) ;
        end
        pdf_gen.w = ones(1,K)/K ;
        
        
        % sample data from the model
        dat = sampleGaussianMixture( pdf_gen, N ) ;
        
        % sample data from the model
        dat_test_data = sampleGaussianMixture( pdf_gen, 10000 ) ;
        
        all_bw_scales = [1:0.1:3] ;
        sel_vl = [100, 1000] ;
        results = zeros(length(all_bw_scales), length(sel_vl)) ;
        
        % initialize
        kde = executeOperatorIKDE( [], 'input_data', dat(:,1:5),'add_input' );
        kde = executeOperatorIKDE( kde, 'compressionClusterThresh', Dth, 'apply_EM_updates', apply_EM_updates ) ;
        for i = 6 : size(dat,2)
            scale_factor_bw_global = 1 ;
            kde = executeOperatorIKDE( kde, 'input_data', dat(:,i), 'add_input'  ) ;
            
            if sum(i==sel_vl)>0
                res =  all_bw_scales*0 ;
                for j = 1 : length(all_bw_scales)
                    bw_scl = all_bw_scales(j) ;
                    scale_factor_bw_global = bw_scl ;
                    kde = executeOperatorIKDE( kde,  'recalculate_bandwidth' ) ;
                    sd = executeOperatorIKDE( kde, 'input_data', dat_test_data, 'evalPdfOnData' ) ;
                    idvalid = sd.evalpdf>0 ;
                    res(j) = -mean(log(sd.evalpdf(idvalid))) ;
                end
                cur_p = (i==sel_vl) ;
                results(:,cur_p) = res' ;
                scale_factor_bw_global = 1 ;
                kde = executeOperatorIKDE( kde,  'recalculate_bandwidth' ) ;
            end
        end 
        Reslt = horzcat(Reslt, results) ;
    end
    r = 0 ; for i_r = 1 : length(Reslt) r = r+Reslt{i_r} ; end 
    r =r/length(Reslt) ;
    
    d_Reslt = horzcat(d_Reslt, r) ;
end
save('c:\Work\a\dim_results.mat','d_Reslt','-mat') ;
return ;

% show a sequence of 2D projections -- this is simply achieved by
% marginalizing out the appropriate dimensions
visualize3D_kde_as_2D_projections( k, 2, 3 ) ;
visualize3D_kde_as_2D_projections( kde, 4, 5 ) ;
 
function EvalOptBWScaleFullTest()
% Contents:
% Samples are generated from 3D mixture model.
% The demo displays the reference 3D model and its current estimate. It
% then visualizes the resulting model as projections to pairs of axes --
% this is just a marginalization of the pdf and visualization of the
% resulting 2D model.
    
global scale_factor_bw_global ;
scale_factor_bw_global = 1 ;
% generate some datapoints 
N = 109 ;
Dth = 0.05; % allowed Hellinger distance error in compression
apply_EM_updates = 0 ; % [ 1 0 ] whether to use the EM updates (a bit faster)
% modd = 500 ;
 
N_exprmnts = 2 ;
all_bw_scales = [0,1,2,3] ; %[1:0.1:3] ;
res = zeros(N_exprmnts,length(all_bw_scales)) ; 

alldims = 2 ; [1 , 5 , 10 ];
d_Reslt = zeros(length(alldims), length(all_bw_scales)) ;
for i_dim = 1 : length(alldims)
    sel_dim = alldims(i_dim) ;
    for r_expr = 1 : N_exprmnts 
        K = 3 ;
        pdf_gen.Mu = rand(sel_dim,K)*10 ; pdf_gen.Cov = {} ;
        for i = 1:K
            pdf_gen.Cov = horzcat(pdf_gen.Cov, 0.5+diag(rand(1,sel_dim)*2)) ;
        end
        pdf_gen.w = ones(1,K)/K ;

        % sample data from the model
        dat = sampleGaussianMixture( pdf_gen, N ) ;
        
        % sample data from the model
        dat_test_data = sampleGaussianMixture( pdf_gen, 10000 ) ;

        for j = 1 : length(all_bw_scales)
            [i_dim, r_expr, j]
            
            %         results = zeros(length(all_bw_scales), length(sel_vl)) ;
            scale_factor_bw_global = all_bw_scales(j) ;
            
            % initialize
            kde = executeOperatorIKDE( [], 'input_data', dat(:,1:5),'add_input' );
            kde = executeOperatorIKDE( kde, 'compressionClusterThresh', Dth, 'apply_EM_updates', apply_EM_updates ) ;
            for i = 6 : size(dat,2)
                kde = executeOperatorIKDE( kde, 'input_data', dat(:,i), 'add_input'  ) ;
            end
            sd = executeOperatorIKDE( kde, 'input_data', dat_test_data, 'evalPdfOnData' ) ;
            idvalid = sd.evalpdf>0 ;
            res(r_expr, j) = -mean(log(sd.evalpdf(idvalid))) ;            
        end        
    end
    results = mean(res,1) ;
    d_Reslt(i_dim, :) = results  ;     
end
save('c:\Work\a\dim_results.mat','d_Reslt','-mat') ;
return ;

% show a sequence of 2D projections -- this is simply achieved by
% marginalizing out the appropriate dimensions
visualize3D_kde_as_2D_projections( k, 2, 3 ) ;
visualize3D_kde_as_2D_projections( kde, 4, 5 ) ;
