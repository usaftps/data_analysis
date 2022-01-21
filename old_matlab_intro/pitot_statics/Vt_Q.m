function Vt = Vt_Q(Q, Ta, Hc)

% determine True Airspeed (KTAS) given:
%    Dynamic Pressure (lb/ft^2),
%    Ambient Temperature (degrees C), and
%    Pressure Altitude (feet)
%
% Written 13 Oct 00 by:  Timothy R. Jorris
%                        TPS\00B

const = declare;

Vt = (sqrt(Q ./ (0.5 * const.Dsl .* Sigma_Hc(Ta, Hc)))/1.6878);