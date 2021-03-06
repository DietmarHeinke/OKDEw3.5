%%
% Originally a part of: Maggot (developed within EU project CogX)
% Author: Matej Kristan, 2009 (matej.kristan@fri.uni-lj.si; http://vicos.fri.uni-lj.si/matejk/)
% Last revised: 2009
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

[ p, model ] = normmixpdf_slow( model, X, diag_noise ) ;

% p = zeros(1,size(X,2)) ;
% for i = 1 :  length(model.w)
%     p = p + model.w(i)*normpdf(X,model.Mu(:,i),[], model.Cov{i}) ; 
% end
     
if nargout == 1 
    model = [] ; 
end