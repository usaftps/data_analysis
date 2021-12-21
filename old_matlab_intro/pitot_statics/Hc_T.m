function Hc=Hc_T(Ta)
% Compute Temperature Altitude given Temperature
% 
%   Hc = Hc_T(Ta)
% 
%     Hc   = pressure altitude (ft)
%     Ta   = ambient temperature (°C)
%     Tsl  = sea level ambient temperature = 288.15 K
% 
% First compute the temperature ratio (theta).
% 
% theta = Ta / Tsl
% 
% The equations relating theta and pressure altitude change at 36,089.24 ft, so compute the break point.
% 
% Hc_break = 36089.24
% Theta_break = Theta(Tstd(Hc_break)) =  .7518651823484
% 
% if theta >= theta_break
% 
%     Hc_T = (1 - theta) / 6.87559e-6
% 
% else
%     Hc_T = 36089.24 (or higher, i.e. this is not a unique answer)
const=declare;
Hc_Break=const.h1;
Ta_Break = Tstd(Hc_Break);
Hc=zeros(size(Ta));
id_lo=(Ta >= Ta_Break);
id_hi=(Ta < Ta_Break);
if const.use_tps    
    Hc(id_lo) = (1 - Theta_Ta(Ta(id_lo))) / 6.87559e-6;
else
    Hc_all=[0:1:Hc_Break]';
    [d,p,Ta_all]=us76_ft(Hc_all);
    Hc(id_lo)=interp1(Ta_all,Hc_all,Ta(id_lo),'linear','extrap');
end
if nnz(id_hi) > 0
    warning(['Non-unique solution for altitudes above ',num2str(Hc_Break)])
    Hc(id_hi) = Hc_Break;
end
    

    
    