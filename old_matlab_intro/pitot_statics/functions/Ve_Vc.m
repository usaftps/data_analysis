function Ve = Ve_Vc(Vc, Hc)
 
% determine Equivalent Airspeed (KEAS) given:
%   Calibrated Airspeed (KCAS),
%   Pressure Altitude (Hc) in feet
%
% Written 7 Oct 00 by:  Timothy R. Jorris
%                       TPS\00B
%Dim Vtrue As Double
%Vtrue = M_Vc(Vc, Hc) * SoS(Tstd(Hc))
%Ve_Vc = Vtrue * Sqr(Sigma(Tstd(Hc), Hc))

const=declare;

Mach = M_Vc(Vc, Hc);
Ve = Mach .* const.asl .* sqrt(Delta_Hc(Hc));