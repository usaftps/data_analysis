function Tt =  Tt_Ta(Ta,M)
% Compute Total Temperature given Ambient Temperature and Mach Number
% 
% Tt_Ta(Ta,M)
% 
%     Tt_Ta = total temperature (°C)
%     Ta    = ambient temperature (°C)
%     M     = mach number (see Note below)
% 
% This is the same as the Tic_Ta computation with Kt = 1
% 
% Ta = T_C2K(Ta)            in Kelvin
% Tt/Ta = 1 + 0.2 · M^2
% 
% Tt = Ta · (1 + 0.2 · M^2) in Kelvin
% Tt_Ta = T_K2C(Tt)         in °C
% 
% Note: Equations are valid across a shock.  Therefore, Ta is in front of
% shock.

Tt = Tic_Ta(Ta, M, 1);