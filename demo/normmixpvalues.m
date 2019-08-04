function [p, pTotal, maxLocs] = normmixpvalues( model, X , diag_noise)

if nargin < 3 || isempty(diag_noise)
    Dn = 0 ;
else
    Dn = eye(size(model.Cov{1},1))*diag_noise ;
end
numData = size(X,2) ;
numcomps = length(model.w) ;
p = zeros(numcomps, numData) ;
pTotal = zeros(1, numData);

d = size(model.Mu,1) ;
a = sqrt(2*pi)^d ;
maxValues = zeros (1, numData);
maxLocs = zeros(1, numData);
mdX = zeros(1, numcomps);
mdXLoc = zeros(1,numData);
for i = 1 : numcomps    
%     dX = X - repmat(model.Mu(:,i),1,numData) ;
    dX = bsxfun(@minus, X, model.Mu(:,i)) ;
    temp = abs(sum(dX));
    mdX(i) = find(min(temp)==temp,1);
    mdXLoc(mdX(i)) = i;
    
    detD = det(model.Cov{i}) ;
    p(i,:) = model.w(i)*(1/(a*sqrt(detD)))*exp(-0.5*sum(dX.*((model.Cov{i}+Dn)\dX),1));        
    pTotal = pTotal + p(i,:);
    
    better = maxValues<p(i,:);
    maxValues(better) = p(i, better);
    maxLocs(better) = i;
end
maxLocs(maxLocs==0&mdXLoc>0) = mdXLoc(maxLocs==0&mdXLoc>0);
end