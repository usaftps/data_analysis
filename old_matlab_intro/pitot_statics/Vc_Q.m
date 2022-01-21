function Vc = Vc_Q(Q, Hc)

% determine Calibrated Airspeed (KCAS) given:
%   Dynamic Pressure (lb/ft^2) and
%   Pressure Altitude (Hc) in feet
%
% Written 13 Oct 00 by:  Timothy R. Jorris
%                        TPS\00B

Mach = M_Q(Q, Hc);
Vc = Vc_M(Mach, Hc);