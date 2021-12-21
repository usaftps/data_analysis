function theta=Theta_Ta(Ta_C)

% Compute theta for T_ambient (degree C) , which is Ta/Tsl
%
%   theta=Theta_Ta(Ta_C)
%
% To compute a standard theta just call =Theta_Ta(Tstd(Hc))
%
% Written 7 Oct 00 by:  Timothy R. Jorris
%                       TPS\00B
const=declare;
theta = (Ta_C + 273.15) / const.Tsl;
    
 end % function