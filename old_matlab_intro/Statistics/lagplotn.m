function lagplotn(resids, n)
%LAGPLOTN Produce a nth lag plot of residuals and show a trend line
%
%       lagplotn(residuals)
%       lagplotn(residuals,n)
%
%   residuals - row or column vector of residuals
%   n         - (optional) plot i versus i+n.  Default is 1 if not provided
% 
% Example:
%   a   = -5; b = 5;                % min to max
%   res = a + (b-a) * rand(101,1);  % residuals with no trend
%   lagplotn(res,2)
%   
% written by: Maj Tim Jorris, TPS/CS, July 2008
%
% See also RESID, COMPARE, and PREDICT

%% Run example if no arguments are given
if nargin==0 % run the example
    a   = -5; b = 5;  % min max
    res = a + (b-a) * rand(100,1);  % residuals with no trend    
    lagplotn(res,2)
    return
end
%% Default value for n
if nargin < 2, n=1; end 

%% Determine the linear trend
len=length(resids);
vec1=resids(1:(len-n));  % keeps number of points - n
vec2=resids(1+n:len);    
% id=[1:(len-n);1+n:len]'; id(1:10,:)
% vec1=resids(1:n:(len-n));  % divids points by n
% vec2=resids(n+1:n:len);
% id=[1:n:(len-n);n+1:n:len]'; id % id(1:5,:)
if length(vec1) >= 2 
    coef=polyfit(vec1,vec2,1); % linear fit
    xlin=linspace(min(vec1),max(vec1),1000);
    ylin=polyval(coef,xlin);  % pretty line values
    yR2 =polyval(coef,vec1);  % same size as original data
    R2=1-sum((yR2-vec2).^2)/sum(vec2.^2); % Excel R2
else
    xlin=NaN; ylin=NaN; R2=NaN; coef=[NaN, NaN];
end
hl=plot(vec1,vec2,'ro',xlin,ylin,'b-',NaN,NaN,'rx'); % NaN is for legend spacing
set(hl(3),'Marker','none')
xlabel('residual ( i )'), ylabel(sprintf('residual ( i + %d )',n))
title(sprintf('Lag Plot: n = %d',n))
hleg=legend(hl(2),...
    sprintf('y  = %.4f x + %.4f; R^2 = %.4f',coef(1),coef(2),R2), ...
    'Location','N');
set(hleg,'Color','None','Box','off') % max legend transparent