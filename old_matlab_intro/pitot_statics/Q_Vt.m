function Q = Q_Vt(Vt, Ta, Hc)

% determine Dynamic Pressure (lb/ft^2) given:
%   True Airspeed (KTAS),
%   Ambient Temperature (degrees C), and
%   Pressure Altitude (feet)
%
% Written 13 Oct 00 by:  Timothy R. Jorris
%                        TPS\00B

const=declare;

Q = 0.5 * const.Dsl * Sigma_Hc(Ta, Hc) .* (Vt*1.6878) .^ 2;