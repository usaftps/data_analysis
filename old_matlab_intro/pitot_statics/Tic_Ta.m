function Tic = Tic_Ta(Ta,M, Kt)
% Compute Instrument Corrected Temperature given Ambient Temperature, Mach
% Number, and Recovery Factor
% 
%   Tic = Tic_Ta(Ta,M,Kt)
% 
%     Tic    = instrument corrected temperature (°C)
%     Ta     = ambient temperature (°C)
%     M      = mach number (see Note below)
%     Kt     = temperature probe recovery factor
% 
% Ta = T_C2K(Ta)                  in Kelvin
% Tic/Ta = 1 + 0.2 · Kt · M^2
% 
% Tic = Ta · (1 + 0.2 · Kt · M^2) in Kelvin
% Tic_Ta = T_K2C(Tic)             in °C
% 
% Note: Equations are valid across a shock.  Therefore, Ta is in front of
% shock. 

Tic_K = (Ta+273.15) .* (1 + 0.2 .* Kt .* M .^ 2);
Tic = Tic_K - 273.15;

