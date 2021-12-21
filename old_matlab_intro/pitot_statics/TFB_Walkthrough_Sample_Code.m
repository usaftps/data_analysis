% ED Quick Review: Pitot-statics
% Sample MATLAB Code
% Written by Juan Silv Jurado, Fall 2019

clear; clc; close all;

% Problem Setup
towerHc = 2010; % Pressure altitude in tower, ft
gridReading = 2.5; % Tower theolodite reading, unitless
towerTa = 29.4; % Tower ambient temperature, deg C
gridConstant = 31.4; % Tower theolodite constant, ft/dif

% Test Point Data
deltaHic = -22; % Altitude instrument correction, ft
deltaVic = 3.0; % Airspeed instrument correction, kts
Hi = 2017; % Indicated altitude, ft
Vi = 302; % Indicated airspeed, kts

% Problem: find Hic, Vic, Hc, deltaHpc, deltaPp_Ps
% Step 1: Instrument corrections
Hic = Hi + deltaHic;
Vic = Vi + deltaVic;
fprintf('Hic: %0.3f ft\n',Hic);
fprintf('Vic: %0.3f kts\n',Vic);

% Step 2: Altitude position-error correction
% Set up basic equations/functions (alts below 36K feet and subsonic)
pressureRatio_H = @(H)  (1 - 6.87559e-6*H).^5.2559; % delta(H)
tempRatio_H = @(H) 1 - 6.87559e-6*H;
Mach_QcPa = @(Qc,Pa) sqrt(5*((Qc/Pa+1)^(2/7)-1));
seaLevelTemp = 15 + 273.15; % deg K
seaLevelPressure = 14.695951733258404; % psi
seaLevelSoS = 661.48; % kts

% Geometric height of aircraft above tower
geometricDelta = gridReading*gridConstant; 

% Convert geometric height difference to pressure altitude difference
Ttest = towerTa+273.15; % Test-day temp at tower, K
Tstd = seaLevelTemp*tempRatio_H(towerHc); % Standard temp at tower alt, K
deltaHc = Tstd/Ttest*geometricDelta; % feet PA

% Compute true pressure altitude at aircraft's fly-by altitude
Hc = towerHc+deltaHc; % True aircraft pressure alt, ft
fprintf('Hc: %0.3f ft\n',Hc);

% Compute altitude position error correction
deltaHpc = Hc-Hic;
fprintf('deltaHpc: %0.3f ft\n',deltaHpc);

% Now convert this altimeter error to pressure error
Pa = seaLevelPressure*pressureRatio_H(Hc);
Ps = seaLevelPressure*pressureRatio_H(Hic);
deltaPp_Ps = (Ps-Pa)/Ps;
fprintf('deltaPp_Ps: %0.4f\n',deltaPp_Ps);

% Step 3: Airspeed and Mach number corrections
% Compute Qcic from Vic and the aircraft altitude
Qcic = seaLevelPressure*((1+0.2*(Vic/seaLevelSoS)^2)^(7/2)-1);

% Correct Qcic into Qc using deltaP_p/Ps from the TFB
Qc = Qcic+(deltaPp_Ps*Ps);

% Use Qc to get Vc, or position corrected airspeed
Vc = seaLevelSoS*sqrt(5*((Qc/seaLevelPressure+1)^(2/7)-1));

% Obtain deltaVpc using Vic and Vc
deltaVpc = Vc-Vic;
fprintf('deltaVpc: %0.4f kts\n',deltaVpc);

% Next, compute Mic and Mpc using Qcic/Ps and Qc/Pa respectively
Mic = Mach_QcPa(Qcic,Ps);
fprintf('Mic: %0.4f\n',Mic);
Mc = Mach_QcPa(Qc,Pa);
deltaMpc = Mc-Mic;
fprintf('deltaMpc: %0.4f\n',deltaMpc);

% Finally, compute deltaPp/Qcic
deltaPp_Qcic = (deltaPp_Ps*Ps)/Qcic;
fprintf('deltaPp_Qcic: %0.4f\n',deltaPp_Qcic);










