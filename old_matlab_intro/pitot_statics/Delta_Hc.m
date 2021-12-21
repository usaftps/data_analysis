function delta=Delta_Hc(Hc)

% Compute Pressure Ratio given Pressure Altitude
%
%   delta=Delta_Hc(Hc)
% 
%     delta = pressure ratio (Pa/Psl)
%     Hc    = pressure altitude (ft)
%
% written by: Maj Tim Jorris, TPS/CS, Feb 2009

const=declare;
[d,Pa]=us76_ft(Hc);
delta = Pa/const.Psl;
