function M = M_Q(Q, Hc)

% determine Mach Number given:
%   Dynamic Pressure (lb/ft^2) and
%   Pressure Altitude (Hc) in feet
%
% Written 13 Oct 00 by:  Timothy R. Jorris
%                        TPS\00B

const=declare;

M = sqrt(Q ./ (0.5 * const.Gamma .* Pstd(Hc)));