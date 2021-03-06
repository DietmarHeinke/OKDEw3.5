function [ p, model ] = normmixpdf( model, X, input_minerr )
%% 
% model.Mu
% model.Cov
% model.w
% model.cached.invCov
% model.cached.logConstant
%
% if one of the output arguments is the model, then the function returns
% the model with cached constants and inverses.
% 
% Matej Kristan 2009
%%
minerr = [] ; %1e-5 ;
if nargin == 3
    minerr = input_minerr ;
end
th_err = log(minerr) ;
haveCached = 0 ; 
log2pi = 1.83787706640935;
[d, numData] = size(X); 
numComps = length(model.w) ;
if isfield(model,'cached')
    if length(model.cached) == numData
        haveCached = 1 ;
    end
end
if haveCached == 0
   model.cached.iS = {} ;
   model.cached.logConstant = [] ;   
end
 
I_noise = eye(size(model.Cov{1})) ;
p = zeros(1,numData) ; 
p_tmp = zeros(1,numData) ;
for i = 1 : numComps
% %     model.Cov{i} = model.Cov{i}*1.5^2
    if haveCached == 0
%         try

%             iS = chol(inv(model.Cov{i} + I_noise*mean(diag(model.Cov{i}))*(1e-3))) ;
%             [U,S,V] = svd(model.Cov{i}) ;
%             S(3,3) = 1e-5 ;
%             model.Cov{i} = U*S*U' ;

            iS = chol(inv(model.Cov{i})) ;
 
 
        logdetiS = sum(log(diag(iS))) ;
 
        logConstant = (logdetiS -0.5*d*log2pi) ;
 
    else
        logConstant = model.cached.logConstant ;
        iS = model.cached.iS ;
    end
%     p = normpdfApprox(X,model.Mu(:,i), S, 'inv', minerr, logConstant ) ;
%     dx = X - repmat(model.Mu(:,i),1,numData) ;
    dx = bsxfun(@minus, X, model.Mu(:,i) ) ;
%     dx = solve_tril(S',dx); 
    
    dx = iS*dx ;
    pl = logConstant - 0.5*col_sum(dx.*dx);
    
    if ~isempty(minerr)
        sel = pl > th_err ;
        p_tmp = p_tmp*0 ;
        p_tmp(sel) = exp(pl(sel)) ;
    else
        p_tmp = exp(pl) ;
    end
%    p_tmp = normpdf(X,model.Mu(:,i),[], model.Cov{i}) ;

    p = p + model.w(i)*p_tmp ;
end
     
if nargout < 2
    model = [] ;
end
    