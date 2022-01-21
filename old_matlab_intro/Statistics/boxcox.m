function v=boxcox(x,lamda,xdot)
%Syntax: v=boxcox(x,lamda,xdot)
%______________________________
%
% Makes the Box-Cox transformation of a data set x.
%
% v is the transformed data vector.
% x is the data set.
% lamda is the parameter of the transformation.
% xdot is the geometric mean of the data.
%
% Alexandros Leontitsis
% Institute of Mathematics and Statistics
% University of Kent at Canterbury
% Canterbury
% Kent, CT2 7NF
% U.K.
% University e-mail: al10@ukc.ac.uk (until December 2001)
% Lifetime e-mail: leoaleq@yahoo.com
% Homepage: http://www.geocities.com/CapeCanaveral/Lab/1421
%
% June 15, 2001.

if nargin<1 || isempty(x)==1
   error('You shoud provide a data set.');
else
   % x must be a vector
   if min(size(x))>1
      error('Invalid data set.');
   end
   x=x(:);
   % n is the data set length
   n=length(x);
end

if nargin<2 || isempty(lamda)==1
   lamda=0;
else
   %lamda must be either a scalar or a vector
   if min(size(lamda))>1
      error('lamda must be either a scalar or a vector.');
   end
end

if nargin<3 || isempty(xdot)==1
   xdot=1;
else
   % xdot must be a scalar
   if sum(size(xdot))>2
      error('xdot must be a scalar.');
   end
end

% Box-Cox transformation
for i=1:length(lamda)
   if lamda(i)~=0
      v(:,i)=(x.^lamda(i)-1)/(lamda(i)*xdot^(lamda(i)-1));
   else
      v(:,i)=xdot*log(x);
   end
end

