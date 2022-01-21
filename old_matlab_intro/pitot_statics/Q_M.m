function qbar=Q_M(Mach , Hc ) 

% Compute Dynamic Pressure given Mach Number and Pressure Altitude
% 
%   qbar = Q_M(M,Hc)
% 
%     qbar  = dynamic pressure (lb/ft^2)
%     M     = mach number
%     Hc    = pressure altitude (ft)
%     Pstd  = standard day pressure (lb/ft^2)
%     gamma = specific heat ratio = 1.4
% 
% Q = 1/2 · rho · Vt^2 = 1/2 · rho · a^2 · M^2
% substitute in: a^2 = gamma · R · T     and    P = rho · R · T
% Q = 1/2 · (P / R · T) · (gamma · R · T) · M^2
% Q = 1/2 · gamma · P · M^2
%
% Written 13 Oct 00 by:  Timothy R. Jorris
%                        TPS\00B

const=declare;
qbar = 0.5 .* const.Gamma .* Pstd(Hc) .* Mach .^ 2;
