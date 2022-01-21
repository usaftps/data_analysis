function Hc = Hc_P(Pa)
% Compute Pressure Altitude given Pressure
% 
% Hc_P(Pa)
% 
%     Hc_P = pressure altitude (ft)
%     Pa   = pressure (lb/ft^2)

%% I don't really want to reverse engineer US76_1000. So, we'll use it and
%% interpolate. This is inefficient, but an easy answer for now.

%% These are the geopotential limit of us76_1000
Hc_km=linspace(-4.002517, 864.0707071,1000000)';
Hc_ft=Hc_km/12/2.54*100*1000;
[d,Pall]=us76_ft(Hc_ft);

Hc = interp1(Pall,Hc_ft,Pa);
% 
% d_Hc=1000; % plus or minus
% Hc_ft=linspace(min(Hc)-d_Hc,max(Hc)+d_Hc,1000)';
% [d,Pall]=us76_ft(Hc_ft);
% Hc = interp1(Pall,Hc_ft,Pa);
% 
% d_Hc=10; % plus or minus
% Hc_ft=linspace(Hc-d_Hc,Hc+d_Hc,10000)';
% [d,Pall]=us76_ft(Hc_ft);
% 
% Hc = interp1(Pall,Hc_ft,Pa);