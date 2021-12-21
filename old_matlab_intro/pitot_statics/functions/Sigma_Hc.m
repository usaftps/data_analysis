function sigma=Sigma_Hc(Ta,Hc)
% Compute Density Ratio given Ambient Temperature and Pressure Altitude
% 
%   Sigma_HC(Ta,Hc)
% 
%     Sigma  = density ratio (lb/ft^2)
%     Ta     = ambient temperature (°C)
%     Hc     = pressure altitude (ft)
%     Delta  = pressure ratio
%     Theta  = temperature ratio
% 
% Sigma = Delta_Hc(Hc) /  Theta_Ta(Ta)
% 
% Hint: the equation =Sigma(Tstd(Hc),Hc) will give standard day density
% ratio at a pressure altitude (Hc).

if Theta_Ta(Ta) == 0
    sigma = 1e+38;
else
    sigma=Delta_Hc(Hc)./Theta_Ta(Ta);
end