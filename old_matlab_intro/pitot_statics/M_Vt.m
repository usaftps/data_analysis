function M = M_Vt(Vt, Ta)

% determine Mach Number given:
%   True Airspeed (KTAS)and
%   Ambient Temperature (degrees C)
%
% Written 9 Oct 00 by:  Timothy R. Jorris
%                       TPS\00B

M = Vt ./ SoS(Ta);