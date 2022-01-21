function Q = Q_Vc(Vc, Hc)

% determine Dynamic Pressure (lb/ft^2) given:
%   Calibrated Airspeed (KCAS) and
%   Pressure Altitude (Hc) in feet
%
% Written 13 Oct 00 by:  Timothy R. Jorris
%                        TPS\00B

const=declare;

Ve = Ve_Vc(Vc, Hc);
Q = 0.5 .* const.Dsl .* (Ve*1.6878) .^ 2;