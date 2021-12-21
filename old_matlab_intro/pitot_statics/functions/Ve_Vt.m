function Ve = Ve_Vt(Vt,Ta,Hc)

% determine Equivalent Airspeed (KEAS) given:
%   True Airspeed (KTAS),
%   Ambient Temperature (degrees C), and
%   Pressure Altitude (Hc) in feet
%
% Written 9 Oct 00 by:  Timothy R. Jorris
%                       TPS\00B

Ve = Vt .* sqrt(Sigma_Hc(Ta, Hc));