function [d,p,t,s,r,g]=us76_ft(Hc_ft)
%US76_FT 1976 Standard Atmosphere using Imperial Units
%
%  [d,p,t,s,r,g]=us76_ft(Hc)
%
% Input:  
%
%   Hc = pressure altitude - ft
%
% Output:
% 	d = density                              slug/ft^3 
% 	p = static pressure                     lb/ft^2
% 	t = temperature                         C
% 	s = speed of sound                      knots 
% 	r = radius from center of Earth, Re+z   ft
% 	g = gravity at z [=G0*(R0/r)^2]         ft/s^2
% 
% written by: Maj Tim Jorris, TPS/CS, Feb 2009
%
% See also US76_1000

% Note: The purpose of this file is the address the convertion for pressure
% altitude and perform a unit conversion without modifying us76_1000

Hc_km=Hc_ft*12*2.54/100/1000;

%% Now we're correct in km, but what is pressure altitude.  If we assume
%  it's most closely equal to potential altitude, the we must convert it to
%  geometric as input for us76_1000.  Geometric altitude is uses since
%  us76_1000 was developed for use with equations of motion, hence inertial
%  or geometric altitude.
const=declare;
if const.use_tps
    ro  = 6356.766/12/2.54*100*1000; % /* radius of Earth - km to ft*/
    g   = const.Gravity; % assumed constant
    id_lo_36=Hc_ft <= const.h1;
    id_36_hi=Hc_ft > const.h1;
    tha=zeros(size(Hc_ft)); dta=tha; sig=tha;
    if nnz(id_lo_36) > 0
        tha(id_lo_36)=1-6.87559e-6*Hc_ft(id_lo_36);
        dta(id_lo_36)=tha(id_lo_36).^5.2559;
        sig(id_lo_36)=tha(id_lo_36).^4.2559;
    end
    if nnz(id_36_hi) > 0
        tha(id_36_hi)=0.751865+0*Hc_ft(id_36_hi); % latter is just for size
        dta(id_36_hi)=0.223360*exp(-4.80637e-5*(Hc_ft(id_36_hi)-const.h1));
        sig(id_36_hi)=0.297075*exp(-4.80637e-5*(Hc_ft(id_36_hi)-const.h1));
    end
    d=sig*const.Dsl;
    p=dta*const.Psl;
    t=tha*const.Tsl-273.15;
    s=sqrt(tha)*const.asl;
    r = Hc_ft + ro; % crude for this model, just to keep outputs same
else
    % Use nasa extended to 1000 km, input must be converted to km
    ro  = 6356.766;       % /* radius of Earth - km */
    Hg_km = Hc_km./(ro./(ro+Hc_km));  % geopotential=press alt to geometric
    [d,p,t,s,r,g]=us76_1000(Hg_km);
    % [d,p,t,s,r,g]
    d=0.00194032072249365*d;  % km/m^3 to slug/ft^3
    p=0.0208854384366071*p;   % N/m^2 to lb/ft^2
    t=t-273.15;               % K to C
    s=1.9438444924406*s;      % m/s^2 to knots
    r=r/12/2.54*100*1000;     % km to ft
    g=g/12/2.54*100*1000;          % m/s^2 to ft^2
end    


