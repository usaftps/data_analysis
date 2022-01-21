function intable = aeromodelingFun(intable, Lxa, zfw)
% This script is used with the enginemodel, and ffactor 
% .mat files to calculate the lift and drag coefficients for a single 
% dataset. 
%
% Written by Capt Tony Luby, TPS 20A
% Updated by Capt Michael Maccha, TPS 20B, 11 Nov 2020
%

% example inputs
% Lxa = 34.5; % ft, length from cg to alpha vanes, need to update
% zfw = 20633.7; % lb, zero fuel weight for aircraft/config flown
% intable = readtable('rc11M30K.xls'); % load test data

load('engine_model') % load engine model tables
load('ffactormodel') % load ffactor tables

% % % % This is an example of where/how you can include your corrections depending 
% % % % on what code you have in place for your TFB corrections
Correct Mach, Altitude, and Velocity with TFB model
[Hpc, Vpc, Mpc] = TFBcorrection(intable.BARO_ALT_1553, intable.CAL_AS_1553, intable.MACH_1553);
intable.BARO_ALT_1553 = Hpc;
intable.CAL_AS_1553 = Vpc;
intable.MACH_1553 = Mpc;

dens_SL = 0.0023769; %sl/ft^3, sea level density
T_SL = 288.15; %K, sea level temperature

% Average fuel weight for aircraft GW
w_fuel = mean(intable.FQT);

% alpha true function
alpha_true = @(alpha, q, Lxa, V_t) alpha + (q*Lxa/V_t);

%Pre-allocate new paramter columns
n = height(intable);
intable.alpha_true = zeros(n,1);
intable.alpha_true_deg = zeros(n,1);
intable.delta = zeros(n,1);
intable.theta = zeros(n,1);
intable.density_ratio = zeros(n,1);
intable.density = zeros(n,1);
intable.f_factor = zeros(n,1);
intable.v_t_calc = zeros(n,1);
intable.nx_calc = zeros(n,1);
intable.Fg = zeros(n,1);
intable.Fe = zeros(n,1);
intable.lift = zeros(n,1);
intable.c_l = zeros(n,1);
intable.drag = zeros(n,1);
intable.c_d = zeros(n,1);

for i=1:n;
    intable.alpha_true(i) = alpha_true((intable.AOA(i)*pi/180), (intable.PITCH_RATE(i)*pi/180), Lxa, intable.TAS_1553(i)*1.689);
    intable.alpha_true_deg(i) = intable.alpha_true(i)*180/pi;
    
    intable.delta(i) = (1 - 6.87559*10^(-6) * intable.BARO_ALT_1553(i))^(5.2559);
    intable.theta(i) = intable.FS_TEMP_K_1553(i) / T_SL; 
    intable.density_ratio(i) = (intable.delta(i) / intable.theta(i));
    intable.density(i) = dens_SL * intable.density_ratio(i);
    
    % Interpolate f factor from f factor table using Vpc and Hpc 
    intable.f_factor(i) = interp2(v_pc_grid,h_pc_grid,f_factor_model, intable.CAL_AS_1553(i),intable.BARO_ALT_1553(i));
    intable.v_t_calc(i) = intable.f_factor(i) * intable.CAL_AS_1553(i) /sqrt(intable.density_ratio(i));
    if i > 10
        intable.nx_calc(i) = (1.689/32.2)*(sum(intable.v_t_calc(i-10:i-1))-sum(intable.v_t_calc(i-9:i))) / (0.5*10);
    else
        intable.nx_calc(i) = 0;  % Data invalid for first 10 points
    end
  
    %Determine Thrust Values - 3 D interpoation of engine model
    intable.Fg(i) = interp3(mach_grid,pla_grid,alt_grid,fg_model, intable.MACH_1553(i), intable.EPLA(i),intable.BARO_ALT_1553(i));
    intable.Fe(i) = interp3(mach_grid,pla_grid,alt_grid,fe_model, intable.MACH_1553(i), intable.EPLA(i),intable.BARO_ALT_1553(i));
   
    % Calculate lift
    intable.lift(i) = ((zfw + w_fuel) / 32.2) * (32.2*intable.nx_calc(i)*sin(intable.alpha_true(i)) + 32.2*intable.NZ(i)*cos(intable.alpha_true(i))) - intable.Fg(i)*sin(intable.alpha_true(i));
    %intable.lift(i) = ((zfw + w_fuel) / 32.2) * (32.2*intable.ACCEL_X_G(i)*sin(intable.alpha_true(i)) - 32.2*intable.ACCEL_Z_G(i)*cos(intable.alpha_true(i))) - intable.Fg(i)*sin(intable.alpha_true(i));
    
    intable.c_l(i) = (2*intable.lift(i)) / (intable.density(i)*((intable.v_t_calc(i)*1.689)^2*300));
    
    %Calculate Drag
    intable.drag(i) = (-1* (zfw + w_fuel) / 32.2) * (32.2*intable.nx_calc(i)*cos(intable.alpha_true(i)) - 32.2*intable.NZ(i)*sin(intable.alpha_true(i))) + intable.Fg(i)*cos(intable.alpha_true(i)) - intable.Fe(i);
    intable.c_d(i) = (2*intable.drag(i)) / (intable.density(i)*((intable.v_t_calc(i)*1.689)^2*300));
end

end