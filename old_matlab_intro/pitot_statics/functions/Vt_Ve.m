function Vt = Vt_Ve(Ve,Ta,Hc)

%determine True Airspeed (KTAS) given:
%   Equivalent Airspeed (KEAS),
%   Ambient Temperature (degrees C), and
%   Pressure Altitude (Hc) in feet
%
% Written 9 Oct 00 by:  Timothy R. Jorris
%                       TPS\00B

Vt = Ve ./ sqrt(Sigma_Hc(Ta, Hc));