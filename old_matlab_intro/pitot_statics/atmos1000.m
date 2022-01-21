function [rho,P,T,s,R,g]=atmos1000(Z,units)
%ATMOS1000 US 1976 Standard Atmosphere with modification to 1000km
%
%   [rho,P,T,s,R,g]=atmos1000(Z)
%   [rho,P,T,s,R,g]=atmos1000(Z)
%
%                                       ('english')     ['metric']
%  Z     - geometric altitude           (ft)            [km]
%  units - 'english' or 'metric'
%  rho   - density                      (slug/ft^3)     [kg/m^3]
%  P     - pressure                     (lb/ft^2)       [Pa = N/m^2]
%  T     - temperature                  (K)             [K]
%  s     - speed of sound               (knots)         [m/s^2]
%  R     - radius from center of Earth  (ft)            [km] geometric
%  g     - gravity                      (ft/s^2)        [km/s^2]
%
% written by: Maj Tim Jorris, TPS/CS, Feb 2009

%% Initialize 
rho=zeros(size(Z)); P=rho; T=P; s=P; R=P; g=P;

%% Ensure altitude input is in units of km
ft2km=12*2.54/100/1000; % 12 in, 2.54 cm to m to km
if nargin > 1 && (abs(units(1))==101 || abs(units(1))==69) % 'e' or 'E'
    Z=Z*ft2km;
end  % Now Z is in km

%% Convert geometric to geopotential
%
% Note: The help uses H for altitude because that's more intuitive. To be
% consistence with USSA:
%
%   H is geopotential, breakpoints <= 86km
%   Z is geometric   , breakpoints >  86km to 1000km
Ro = 6356.766; % km, from U.S. Standard Atmosphere (USSA)
go = 9.80665;  % m/s^2
H  = Z.*(Ro./(Ro+Z)); % converts geometric to geopotential

%% Break up the alitude bands: geopotental < 86km, geometric above
B=[0    11 20  32   47   51   71  86  91  110  120 500 1000]; % breakpoints
L=[-6.5 0  1.0 2.8  0.0 -2.8 -2 0 0 12   12  12  12];
id = logical(zeros(length(Z),13)); Tsl=288.15; TB=zeros(12,1);
for j=1:12
    if j==1
        id(:,j) = Z <= B(j+1);  % one sided at zero
         dH=Z(id(:,j))-B(j);
    elseif j<=6
        id(:,j) = Z >  B(j) & Z <= B(j+1); % 0 to 71K
        DH=B(j)-B(j-1); % whole big block
        dH=Z(id(:,j))-B(j);
    elseif j==7
        id(:,j) = Z >  B(j) & H <= B(j+1); % 71K to 86K
        DH=B(j)/(Ro./(Ro+B(j+1)))-B(j-1);
        dH=Z(id(:,j))-B(j);
    elseif j==12
        id(:,j) = H >  B(j);             % greater than 500
        dH=H(id(:,j))-B(j);
    else
        id(:,j) = H >  B(j) & H <= B(j+1); % 86K to 500K
        DH=B(j)-B(j-1);
        dH=H(id(:,j))-B(j);
    end
    if j==1
        TB(j)=Tsl;
    elseif j <= 12 
        TB(j)=TB(j-1)+L(j-1)*DH;
    end
end
for j=1:12
    if j <= 6
        dH=Z(id(:,j))-B(j);
    else
        dH=H(id(:,j))-B(j);
    end
    T(id(:,j))=TB(j)+L(j)*dH;
end
% for i=[0:12]+1
%     fprintf('%d\n',i)
% end
    
rho=T;
%     
% switch units
%     case 'metric', Z = Z*ft2km;
%     otherwise % it's assumed to be in feet
% end