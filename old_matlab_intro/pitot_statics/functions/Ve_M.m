function Ve=Ve_M(M,Hc)
% Compute Equivalent Airspeed given Mach Number and Pressure Altitude
% 
%   Ve = Ve_M(M,Hc)
% 
%     Ve    = equivalent airspeed
%     M     = mach number
%     Hc    = pressure altitude (ft)
%     Vt    = true airspeed (KTAS)
%     a     = speed of sound (knots)
%     asl   = speed of sound at sea level = 661.48 knots
% 
% Start with the definition of Mach Number:
% 
% M = Vt / a = Ve/sqrt(sigma) / (asl · sqrt(theta))
% 
% since sigma = delta/theta
% 
% Ve_M = M · asl · sqrt(Delta(Hc))
const=declare;

Ve = M .* const.asl .* sqrt(Delta_Hc(Hc));

