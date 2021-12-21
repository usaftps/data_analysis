function [zeta,wn] = logdecr(all_pts)

[junk,id]=sort(all_pts(:,1));
all_pts=all_pts(id,:);
pt1=all_pts(1,:);
pt2=all_pts(2,:);
pt3=all_pts(3,:);
T=pt3(1)-pt1(1);
[zeta,wn]=local_logdecr(T,pt1(2),pt2(2),pt3(2));

function [zeta,wn]   = local_logdecr(arg1,arg2,arg3,arg4);
% LOGDECR
%
%  This file contains the equations used to compute
%  damping (zeta) and natural frequency (wn) from flight 
%  test data using the log decrement method.  This 
%  method is described in the paper titled 
%  "Comparison of Methods for Determining Zeta and Wn 
%  From Flight Test Data", Jan 1968, FTC-TIM-68-1002.  It
%  is assumed that the peaks are referenced to a zero baseline.
%  
%  Inputs:  T - computed period in seconds
%           pk1 - raw value of first peak selected
%           pk2 - raw value of second peak selected
%           pk3 - raw value of third peak selected
%
%  Outputs: zeta - computed damping value
%        wn - computed natural frequency
%
%  Zeta and wn can be computed from either two or three
%  peaks, i.e. if only three inputs are passed to this
%  function then two peaks are used (half cycle).  If four inputs
%  are passed then three peaks are used (full cycle).
%
%  By:  David R. McDaniel, 420 FLTS/ENFC, 21 July 97
%
%  Sign Correction by: Timothy R. Jorris, 445 FLTS/DOES, 26 May 98

% Perform computations based on number of inputs

if nargin == 4,      % Using three peaks - full cycle method

   pk1 = arg2;
   pk2 = arg3;
   pk3 = arg4;
   T = arg1;
   delta1 = abs(pk1-pk2); 
   delta2 = abs(pk2-pk3);

   % Compute damping magnitude

   zeta = (1 + (pi^2)/((log(delta1/delta2))^2))^(-1*0.5);

   % Check for negative damping

   zeta = sign(delta1-delta2)*zeta;

   %if (abs(pk2)>abs(pk1))&(abs(pk3)>abs(pk1))
   %   sn = -1;
   %   zeta = zeta * sn;
   %end

   % Compute damped frequency

   wd = (2*pi)/T;

   % Compute natural frequency

   wn = (wd/((1-zeta^2)^(0.5)));

elseif nargin == 3,  % Using two peaks - half cycle method

   T = arg1;
   % Only want magnitude of peaks
   pk1 = abs(arg2);
   pk2 = abs(arg3);

   % Compute damping magnitude

   zeta = (1 + (pi^2)/((log(pk1/pk2))^2))^(-1*0.5);

   % Check for negative damping

   if (pk2>pk1),
      sn = -1;
      zeta = zeta * sn;
   end

   % Compute damped frequency

   wd = (2*pi)/T;

   % Compute natural frequency

   wn = (wd/((1-zeta^2)^(0.5))); 

else

   % If something isn't expected, send back zero values
   zeta = 0;
   wn = 0;
   return;

end
%%%%%%%%%%%%%%%%%%%% End of File %%%%%%%%%%%%%%%%%%%%
