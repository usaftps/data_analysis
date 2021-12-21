function const=declare
%DECLARE From the Declaration section of Excel FTAS Converter
%
% 'Speed of Sound at sea level
% Option Base 1 ' First index for Arrays is 1
% Public Const asl  As Double = 661.48         ' knots
% Public Const Tsl As Double = 288.15          ' Kelvin
% Public Const Psl As Double = 2116.22         ' lb/ft^2
% Public Const Dsl As Double = 0.0023769       ' slug/ft^3
% Public Const Gamma As Double = 1.4           ' specific heat ratio for air
% Public Const Gravity As Double = 32.174      ' ft/sec^2
% 'Qc/Pa at Mach=1 or Qc/Psl at Vc/asl=1
% Public Const QcP_Break As Double = 0.892929158737854  'Vc=asl or M=1 => (1+0.2*(1))^3.5-1
% Public Const K3 As Double = 166.921580093168 ' ( (36/5)^3.5 )/6
% Public Const K4 As Double = 1.28755526120762 ' K3/7^2.5
% Public Const VelPrec As Double = 2
% Public Const MacPrec As Double = 5
% Public Const Pi As Double = 3.14159265358979
% Public Const ComputeT2 As Boolean = False
const.use_tps=true;  % true is TPS approximation, false is NASA to 1000km
ro  = 6356.766;  const.ro=ro;     % /* radius of Earth - km */
Hg_km_max = 1000; % geometric km
Hp_km_max = Hg_km_max*ro/(ro+Hg_km_max);
const.Hc_max = Hp_km_max*1000*100/2.54/12;
if const.use_tps
    const.h1=36089.24;     % Erb's  breakpoint: assumes geop = geom
    const.h2=65616.80;     % 20 km goepotential
    const.asl       = 661.48;       % knots
    const.Tsl       = 288.15;       % Kelvin
    const.Psl       = 2116.22;      % lb/ft^2
    const.Dsl       = 0.0023769;    % slug/ft^3
    Hp_ft    =[0;const.h1;const.h2;const.Hc_max];
else
    %% These are consistent with us76_1000, so ratios equal 1
    % const.h1=36152;        % 11 km geopotential converted to ft geometric
    % const.h2=82345;        % 25 km geopotential converted to ft geometric 
    const.h1=36089.0170687481;
    const.h2=65616.3946697507;
    const.asl       = 661.478827231622;       % knots
    const.Tsl       = 288.15;       % Kelvin
    const.Psl       = 2116.21704958921;      % lb/ft^2
    const.Dsl       = 0.00237689124720616;    % slug/ft^3
    const.Gamma     = 1.4;          % specific heat ratio for air
    % Account for all the breakpoints
    zs = [... %    /* altitude independent variable (km) */
      0.,       11.019, 20.063, 32.162, 47.35, ... 
      51.413,   71.802, 86.,    91.,    94.,   ... 
      97.,      100.,   103.,   106.,   108.,  ...
      110.,     112.,   115.,   120.,   125.,  ... 
      130.,     135.,   140.,   145.,   150.,  ... 
      155.,     160.,   165.,   170.,   180.,  ... 
      190.,     210.,   230.,   265.,   300.,  ... 
      350.,     400.,   450.,   500.,   550.,  ... 
      600.,     650.,   700.,   750.,   800.,  ... 
      850.,     900.,   950.,   1000., ...
   ];
    Hp_km=zs*ro./(ro+zs);
    Hp_ft=Hp_km'*1000*100/2.54/12;
end
Hp_ft=sort([[min(Hp_ft):100:max(Hp_ft)]';Hp_ft]);   % more dense pattern
Hp_ft(diff(Hp_ft)==0)=[];                           % remove repeats
const.Hc_all=Hp_ft;                                 % assign const

const.Gamma     = 1.4;          % specific heat ratio for air
const.Gravity   = 32.174;       % ft/sec^2
const.QcP_Break = (1+0.2*(1))^3.5-1; % 0.892929158737854; % Vc=asl or M=1 => (1+0.2*(1))^3.5-1
const.K3        = ( (36/5)^3.5 )/6;  % 166.921580093168; % ( (36/5)^3.5 )/6;
const.K4        = const.K3/7^2.5;    % 1.28755526120762;         % K3/7^2.5;
const.MacPrec   = 9; % do to iteration, a limit is here to force
const.VelPrec   = 9; % Vc and M to be converted back to the original
%% Altitude breakpoints
% 11 km and 25km        hgp=hgm.*(ro./(ro+hgm)).^2;
% ro  = 6356.766;         % km
% h1=11; h2=25;           % geopotential
% const.h1=h1/(ro/(ro+h1))/1.609344*5280; % ft
% const.h2=h2/(ro/(ro+h2))/1.609344*5280; % ft
% K1 =  .892929158737854 which is Qc/Psl at Vc/asl=1. See M_Vc
% K3 =  166.921580093168 which is ( (36/5) ^ 3.5 ) / 6
% K4 =  1.28755526120762 which is K3 / 7^2.5
