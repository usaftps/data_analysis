function Vc = Vc_Vt(Vt, Ta, Hc)

% determine Calibrated Airspeed (KCAS) given:
%   True Airspeed (KTAS),
%   Ambient Temperature (degrees C), and
%   Pressure Altitude (feet)
%
% Written 9 Oct 00 by:  Timothy R. Jorris
%                       TPS\00B

M = Vt ./ SoS(Ta);
Vc = Vc_M(M, Hc);