function Vt = Vt_Vc(Vc, Ta, Hc)
 
% determine True Airspeed (KTAS) given:
%   Calibrated Airspeed (KCAS),
%   Ambient Temperature (degrees C), and
%   Pressure Altitude (feet)
%
% Written 7 Oct 00 by:  Timothy R. Jorris
%                       TPS\00B

Vt = M_Vc(Vc, Hc) .* SoS(Ta);