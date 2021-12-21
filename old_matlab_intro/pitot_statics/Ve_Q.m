function Ve = Ve_Q(Q)

% determine Equivalent Airspeed (KEAS) given:
%    Dynamic Pressure (lb/ft^2)
%
% Written 13 Oct 00 by:  Timothy R. Jorris
%                        TPS\00B

const=declare;

Ve = (sqrt(Q ./ (0.5 * const.Dsl))/1.6878);