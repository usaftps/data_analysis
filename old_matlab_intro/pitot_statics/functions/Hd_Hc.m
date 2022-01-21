function Hd = Hd_Hc(Ta,Hc) 
% Compute Density Altitude given Ambient Temperature and Pressure Altitude
% 
%   HcD = Hc_D(Ta,Pa)
% 
%     HD   = density altitude (feet)
%     Ta   = ambient temperature (°C)
%     Hc   = pressure altitude (ft)
%     Psl  = sea level pressure = 2116.22 lb/ft^2
%     Tsl  = sea level ambient temperature = 288.15 K
% 
% First compute the density ratio (sigma), which is the pressure ratio
% (delta) divided by the temperature ratio (theta). 
% 
% delta = Pa / Psl
% theta = (Ta + 273.15) / Tsl
% sigma = delta / theta
% 
% The equations relating sigma and pressure altitude change at 36,089.24
% ft, so compute the break point.  To compute this using existing routines
% we need to know the temperature at 36,089.24 ft.
% 
% Hc_break = 36089.24
% Ta_break = Tstd(Hc_break)
% sigma_break = Sigma(Ta_break,Hc_break) =  .297073637935268
% 
% if sigma >= sigma_break
% 
%     Hc_D = (1 - sigma ^ (1 / 4.2559)) / 6.87559e-6
% 
% else
%            ln (sigma / (0.22336 / 0.751865))
%     Hc_D = ————————————————————————————————— + 36089.24
%                     -4.80637e-5

const=declare;
Hc_break = const.h1;
Ta_break = Tstd(Hc_break);
sigma_break = Sigma_Hc(Ta_break,Hc_break);
sigma=Sigma_Hc(Ta,Hc);
Hd=zeros(size(Ta));
if const.use_tps
    id_lo=sigma >= sigma_break;
    id_hi=sigma <  sigma_break;
    Hd(id_lo) = (1 - sigma(id_lo) .^ (1 / 4.2559)) / 6.87559e-6;
    Hd(id_hi) = log( sigma(id_hi)/(0.22336 / 0.751865))/-4.80637e-5 + Hc_break;
else
    Hc_all=const.Hc_all;
    d_all=us76_ft(Hc_all);
    sig_all=d_all/const.Dsl;
    Hd=interp1(sig_all,Hc_all,sigma);
end
    
    
    
