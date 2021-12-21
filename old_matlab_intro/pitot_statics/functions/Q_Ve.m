function Q = Q_Ve(Ve)

% determine Dynamic Pressure (lb/ft^2) given:
%   Equivalent Airspeed (KEAS)
%
% Written 13 Oct 00 by:  Timothy R. Jorris
%                        TPS\00B

const=declare;

Q = 0.5 * const.Dsl * (Ve*1.6878) .^ 2;