function [kde]=quickStart_oKDE(data, Dth, kde)
% 
% This is a skeleton you can use to get the oKDE [1] quickly up and running
% your own data.
%
% [1] Kristan Matej, Leonardis Ales and Skocaj Danijel, "Multivariate Online Kernel Density Estimation with Gaussian Kernels", 
% Pattern Recognition, 2011.
%
% Author: Matej Kristan, 2013.

% first install the oKDE toolbox
% installEntireMaggot3() ; 

% we'll assume your data is in "dat", which is DxN matrix, D being the
% dimension of datapoints and N being the number of datapoints
D = 1  ;
dat = data'; % replace this with your own data!
% dat = randn(D,N);
% Note: if you have access to your datapoints in advance, or if you have a
% fair sample from your data points, you can use this to prescale your data
% prior to learning in the oKDE. This is especially convenient when the
% scale in one dimension (or subsspace) is significantly larger than in the
% other. Note that the oKDE will take care of this prescaling internally,
% but I still suggest that if you are able to provide some scaling factors
% in advance, you should do so.
% prescaling = 1 ;
% if prescaling
%     [ Mu, T, dat] = getDataScaleTransform( dat ) ;
%     dat = applyDataScaleTransform( dat, Mu, T ) ;    
% end

% initialize your KDE. Again, the oKDE has many valves to make it robust
% against poor initialization, but, if you can, it is recomended that you
% initialize it with sufficiently large sample set (N_init). A rule of thumb would
% be to initialize with more samples than twice the dimensionality of your data.

% Training with smaller samples produces KDE faster.
N_init = size(dat,2);  % how many samples will you use for initialization?
if (N_init > 20)
    kde = executeOperatorIKDE( kde, 'input_data', dat(:,1:20),'add_input' );
    finished = 0;
    
    dat = dat(:,21:end);
else
    kde = executeOperatorIKDE( kde, 'input_data', dat(:,1:N_init),'add_input' );
    finished = 1;
end

kde = executeOperatorIKDE( kde, 'compressionClusterThresh', Dth ) ;

while ~finished
    N_init = size(dat,2);  % how many samples will you use for initialization?
    if (N_init > 20)
        kde = executeOperatorIKDE( kde, 'input_data', dat(:,1:20),'add_input' );
    
        dat = dat(:,21:end);
    else
        kde = executeOperatorIKDE( kde, 'input_data', dat(:,1:N_init),'add_input' );
        finished = 1;
    end
end
end


% --------------------------------------------------------------------- %



