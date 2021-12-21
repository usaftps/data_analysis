function M = M_Ve(Ve, Hc)

% determine Mach Number given:
%   Equivalent Airspeed (KEAS),
%   Pressure Altitude (feet)
%
% Written 9 Oct 00 by:  Timothy R. Jorris
%                       TPS\00B

%Vcal = Vc_Ve(Ve, Hc)
%M_Ve = M_Vc(Vcal, Hc)
%M=Vt/a
%Ve=Sqr(sigma)*Vt=Sqr(delta/sigma)*(asl*sqr(theta))*M

const=declare; 

M = Ve ./ (const.asl * sqrt(Delta_Hc(Hc)));