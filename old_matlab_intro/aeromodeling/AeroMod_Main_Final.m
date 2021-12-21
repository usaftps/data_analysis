%% Main Aeromod script
% This script is used with the aeromodelingFun, enginemodel, and ffactor 
% .mat files to calculate the lift and drag coefficients. 
%
% Written by Capt Michael Maccha, TPS 20B, 11 Nov 2020
%
% This code will process the data into a structure for each mach and
% manuever, plotting and model curves need to be MANUALLY updated for your 
% specific conditions. Addittionally, it is recommended that your specific 
% TFB corrections are included in this script or the aeromodelingFun code

clear all, close all, clc

% Aircraft characteristics - UPDATE THESE VALUES
Lxa = 34.5; % ft, length from cg to alpha vanes (doesn't make huge difference just estimate the distance)
zfw = 20633.7; % lb, zero fuel weight for aircraft/config flown


%% Create Data Structure
% Uncomment mach ranges tested

Data = struct;
Data.mach6 = struct;
Data.mach7 = struct;
% Data.mach8 = struct;
% Data.mach9 = struct;
% Data.mach95 = struct;
% Data.mach11 = struct;

%% CSV filenames
% Each Mach is a singe row, add the file names for manuever and altitude as
% follows:
% At a specific Mach [WUT at 25K, WUT at 30K, Rollercoaster at 25K, Rollercoaster at 30K, SplitS at 30K]
% Add as many rows as required, order needs to match structure above 
fileNames = {'wut06M25K.xls', 'wut06M30K.xls', 'rc06M25K.xls','rc06M30K.xls', 'split06M_N.xls';...
             'wut07M25K.xls', 'wut07M30K.xls', 'rc07M25K.xls','rc07M30K.xls', 'split07M_N.xls'};

         
%% Import data
mach = fieldnames(Data);

for k = 1:length(mach)
    Data.(mach{k}).wut = struct;
    Data.(mach{k}).rc = struct;
    Data.(mach{k}).split = struct;

    %Wind up Turns
    Data.(mach{k}).wut.alt25 = readtable(fileNames{k,1}); % load test data 
    Data.(mach{k}).wut.alt30 = readtable(fileNames{k,2}); % load test data 

    %Rollercoasters
    Data.(mach{k}).rc.alt25 = readtable(fileNames{k,3}); % load test data 
    Data.(mach{k}).rc.alt30 = readtable(fileNames{k,4}); % load test data 

    %Split S
    Data.(mach{k}).split.alt30 = readtable(fileNames{k,5}); % load test data 
    
    %Calculate cL and cD
    man = fieldnames(Data.(mach{k}));
    alt = fieldnames(Data.(mach{k}).rc);

    for i = 1:length(man);
        alt = fieldnames(Data.(mach{k}).(man{i}));
        for j = 1:length(alt);
            Data.(mach{k}).(man{i}).(alt{j}) = aeromodelingFun(Data.(mach{k}).(man{i}).(alt{j}),Lxa,zfw);
        end
    end
end
%% Generate cL and cD model lines 

% Centerline Tank C_L curve
cl_model_sub = @(alpha) (-4*10^(-10)*alpha^6) + (4*10^(-8)*alpha^5) + (-5*10^(-7)*alpha^4) + (-2*10^(-5)*alpha^3) + (-0.0007*alpha^2) + (0.0828*alpha) + 0.0035;
cl_model_super = @(alpha) (-1*10^(-11)*alpha^6) + (-4*10^(-9)*alpha^5) + (8*10^(-7)*alpha^4) + (-3*10^(-5)*alpha^3) + (-0.0005*alpha^2) + (0.0781*alpha) - 0.0148;

% Subsonic Centerline Tank Drag Polar
cd_model_pt6M = @(cl) (-0.1668*cl^6) + (0.4089*cl^5) + (-0.1686*cl^4) + (-0.079*cl^3) + (0.1941*cl^2) + (-0.0202*cl) + 0.0219;
cd_model_pt7M = @(cl) (-0.3132*cl^6) + (0.7946*cl^5) + (-0.4806*cl^4) + (0.0057*cl^3) + (0.1903*cl^2) + (-0.0195*cl) + 0.0219;
cd_model_pt8M = @(cl) (-0.4375*cl^6) + (1.1022*cl^5) + (-0.6975*cl^4) + (0.0447*cl^3) + (0.1958*cl^2) + (-0.0211*cl) + 0.0225;
cd_model_pt9M = @(cl) (-0.4394*cl^6) + (1.2282*cl^5) + (-1.0214*cl^4) + (0.3113*cl^3) + (0.1448*cl^2) + (-0.024*cl)  + 0.0235;
cd_model_pt95M = @(cl) (-0.1329*cl^6) + (0.4912*cl^5) + (-0.5904*cl^4) + (0.3656*cl^3) + (0.0975*cl^2) + (-0.0181*cl) + 0.0313;
cd_model_pt_super = @(cl) (0.2521*cl^6) + (-0.7438*cl^5) + (0.7438*cl^4) + (-0.2154*cl^3) + (0.2504*cl^2) + (-0.0216*cl) + 0.0505;

% Generate plot data from model
plot_aoas = linspace(-10,27,100);
for i = 1:100
cl_model_sub_plot(i) = cl_model_sub(plot_aoas(i));
cl_model_super_plot(i) = cl_model_super(plot_aoas(i));
end

%subsonic boundaries
cl_model_sub_minus = cl_model_sub_plot-0.1;
cl_model_sub_plus = 0.1+cl_model_sub_plot;

%Supersonc boundaries
cl_model_super_minus = cl_model_super_plot-0.1;
cl_model_super_plus = 0.1+cl_model_super_plot;

plot_cls = linspace(-0.2,1.2,100);
for i = 1:100
cd_model_pt6M_plot(i) = cd_model_pt6M(plot_cls(i));
cd_model_pt7M_plot(i) = cd_model_pt7M(plot_cls(i));
cd_model_pt8M_plot(i) = cd_model_pt8M(plot_cls(i));
cd_model_pt9M_plot(i) = cd_model_pt9M(plot_cls(i));
cd_model_pt95M_plot(i) = cd_model_pt95M(plot_cls(i));
cd_model_super_plot(i) = cd_model_pt_super(plot_cls(i));
end


%0.6M boundaries
cd_model_pt6M_minus = cd_model_pt6M_plot-0.03;
cd_model_pt6M_plus = 0.03+cd_model_pt6M_plot;
%0.7M boundaries
cd_model_pt7M_minus = cd_model_pt7M_plot-0.03;
cd_model_pt7M_plus = 0.03+cd_model_pt7M_plot;
%0.8M boundaries
cd_model_pt8M_minus = cd_model_pt8M_plot-0.03;
cd_model_pt8M_plus = 0.03+cd_model_pt8M_plot;
%0.9M boundaries
cd_model_pt9M_minus = cd_model_pt9M_plot-0.03;
cd_model_pt9M_plus = 0.03+cd_model_pt9M_plot;
%0.95M boundaries
cd_model_pt95M_minus = cd_model_pt95M_plot-0.03;
cd_model_pt95M_plus = 0.03+cd_model_pt95M_plot;
%1.1M boundaries
cd_model_super_minus = cd_model_super_plot-0.03;
cd_model_super_plus = 0.03+cd_model_super_plot;



%% plot points - 0.6M 25K points
k = 1;  % select first mach (0.6 Mach)

% select desired data to trim/decimate data
wutDecimateFactor = 2;  % plot every ___ point
rcDecimateFactor = 10;

%wut data
wut_alpha = Data.(mach{k}).wut.alt25.alpha_true_deg;
wut_cL = Data.(mach{k}).wut.alt25.c_l; 
wut_cD = Data.(mach{k}).wut.alt25.c_d;
wutIndex = [1:wutDecimateFactor:length(wut_alpha)];

%rc data
rc_alpha = Data.(mach{k}).rc.alt25.alpha_true_deg;
rc_cL = Data.(mach{k}).rc.alt25.c_l;
rc_cD = Data.(mach{k}).rc.alt25.c_d;
rcIndex = [1:rcDecimateFactor:length(rc_alpha)];

%%%%%%%%%% plot settings %%%%%%%%%
setFigDefaults; % A simple script to get fonts and font sizes ready
% CL vs alpha
f = figure('Units','inches')  ; % Instantiate a figure object
f.Position = [0 0 11 8.5]; % [x, y, width, height] in inches
hold on

% flight data
scatter(wut_alpha(wutIndex),wut_cL(wutIndex),'o',...
    'MarkerFaceColor','k','MarkerEdgeColor','k') %Wind Ups
scatter(rc_alpha(rcIndex),rc_cL(rcIndex),'s',...
    'MarkerEdgeColor','k') % Roller Coasters

% model data
plot(plot_aoas,cl_model_sub_plot, 'k','Linewidth',2)
plot(plot_aoas,cl_model_sub_minus, 'k:','Linewidth',1)
plot(plot_aoas,cl_model_sub_plus, 'k:','Linewidth',1)

title('Lift Curve - 0.6 Mach - 25,000 ft')
xlabel('Angle of Attack, $\alpha$ (deg)')
ylabel('Lift Coefficient, $C_L$')
axis([-5 30 -.2 1.6])
set(gca,'XMinorTick','on','YMinorTick','on','YAxisLocation','origin','XAxisLocation','origin')
legend('Wind Up Turn', 'Roller Coaster','Location','east');

% CL vs CD
f = figure('Units','inches')  ; % Instantiate a figure object
f.Position = [0 0 11 8.5]; % [x, y, width, height] in inches
hold on

%flight data
scatter(wut_cD(wutIndex),wut_cL(wutIndex),'o',...
    'MarkerFaceColor','k','MarkerEdgeColor','k') %Wind Ups
scatter(rc_cD(rcIndex),rc_cL(rcIndex),'s',...
    'MarkerEdgeColor','k') % Roller Coasters

% model data
plot(cd_model_pt6M_plot,plot_cls, 'k','Linewidth',2)
plot(cd_model_pt6M_minus,plot_cls, 'k:','Linewidth',1)
plot(cd_model_pt6M_plus,plot_cls, 'k:','Linewidth',1)

title('Drag Polar - 0.6 Mach - 25,000 ft')
xlabel('Drag Coefficient, $C_D$')
ylabel('Lift Coefficient, $C_L$')
axis([-.1 1 -.2 1.6])
set(gca,'XMinorTick','on','YMinorTick','on','YAxisLocation','origin','XAxisLocation','origin')
legend('Wind Up Turn', 'Roller Coaster','Location','east');

% Calculate average difference
cL = [rc_cL; wut_cL];
cD = [rc_cD; wut_cD];
alpha= [rc_alpha; wut_alpha];

% reset diff values
dif_cL = zeros(1,length(cL));
dif_cD = zeros(1,length(cL));
for i=1:length(cL)
    dif_cL(i) = cl_model_sub(alpha(i)) - cL(i);
    dif_cD(i) = cd_model_pt6M(cL(i)) - cD(i);
end

avg_cL_6M_25 = mean(dif_cL)
avg_cD_6M_25 = mean(dif_cD)
    
%% 0.6M 30K points
k = 1;  % select first mach (0.6 Mach)

% select desired data 1trim/decimate data
wutDecimateFactor = 5;  % plot every ___ point
rcDecimateFactor = 10;
splitDecimateFactor = 5;
% 30K points

%wut data
wut_alpha = Data.(mach{k}).wut.alt30.alpha_true_deg;
wut_cL = Data.(mach{k}).wut.alt30.c_l; 
wut_cD = Data.(mach{k}).wut.alt30.c_d;
wutIndex = [1:wutDecimateFactor:length(wut_alpha)];

%rc data
rc_alpha = Data.(mach{k}).rc.alt30.alpha_true_deg;
rc_cL = Data.(mach{k}).rc.alt30.c_l;
rc_cD = Data.(mach{k}).rc.alt30.c_d;
rcIndex = [1:rcDecimateFactor:length(rc_alpha)];

% split data
split_alpha = Data.(mach{k}).split.alt30.alpha_true_deg;
split_cL = Data.(mach{k}).split.alt30.c_l;
split_cD = Data.(mach{k}).split.alt30.c_d;
splitIndex = [1:splitDecimateFactor:length(split_alpha)];

%%%%%%%%%% plot settings %%%%%%%%%

setFigDefaults; % A simple script to get fonts and font sizes ready
% CL vs alpha
f = figure('Units','inches')  ; % Instantiate a figure object
f.Position = [0 0 11 8.5]; % [x, y, width, height] in inches
hold on

% flight data
scatter(wut_alpha(wutIndex),wut_cL(wutIndex),'o',...
    'MarkerFaceColor','k','MarkerEdgeColor','k') %Wind Ups
scatter(rc_alpha(rcIndex),rc_cL(rcIndex),'s',...
    'MarkerEdgeColor','k') % Roller Coasters
scatter(split_alpha(splitIndex),split_cL(splitIndex),'^',...
    'MarkerEdgeColor','k') % Split S

% model data
plot(plot_aoas,cl_model_sub_plot,'k','Linewidth',2)
plot(plot_aoas,cl_model_sub_minus,'k:','Linewidth',1)
plot(plot_aoas,cl_model_sub_plus,'k:','Linewidth',1)

title('Lift Curve - 0.6 Mach - 30,000 ft')
xlabel('Angle of Attack, $\alpha$ (deg)')
ylabel('Lift Coefficient, $C_L$')
axis([-5 30 -.2 1.6])
set(gca,'XMinorTick','on','YMinorTick','on','YAxisLocation','origin','XAxisLocation','origin')
legend('Wind Up Turn', 'Roller Coaster','Split S','Location','east');

% CL vs CD
f = figure('Units','inches')  ; % Instantiate a figure object
f.Position = [0 0 11 8.5]; % [x, y, width, height] in inches
hold on

%flight data
scatter(wut_cD(wutIndex),wut_cL(wutIndex),'o',...
    'MarkerFaceColor','k','MarkerEdgeColor','k') %Wind Ups
scatter(rc_cD(rcIndex),rc_cL(rcIndex),'s',...
    'MarkerEdgeColor','k') % Roller Coasters
scatter(split_cD(splitIndex),split_cL(splitIndex),'^',...
    'MarkerEdgeColor','k') % Split S

% model data
plot(cd_model_pt6M_plot,plot_cls, 'k','Linewidth',2)
plot(cd_model_pt6M_minus,plot_cls, 'k:','Linewidth',1)
plot(cd_model_pt6M_plus,plot_cls, 'k:','Linewidth',1)

title('Drag Polar - 0.6 Mach - 30,000 ft')
xlabel('Drag Coefficient, $C_D$')
ylabel('Lift Coefficient, $C_L$')
axis([-.1 1 -.2 1.6])
set(gca,'XMinorTick','on','YMinorTick','on','YAxisLocation','origin','XAxisLocation','origin')
legend('Wind Up Turn', 'Roller Coaster','Split S','Location','east');

% Calculate average difference
cL = [rc_cL; wut_cL; split_cL];
cD = [rc_cD; wut_cD; split_cD];
alpha= [rc_alpha; wut_alpha; split_alpha];

% reset diff values
dif_cL = zeros(1,length(cL));
dif_cD = zeros(1,length(cL));
for i=1:length(cL)
    dif_cL(i) = cl_model_sub(alpha(i)) - cL(i);
    dif_cD(i) = cd_model_pt6M(cL(i)) - cD(i);
end

avg_cL_6M_30 = mean(dif_cL)
avg_cD_6M_30 = mean(dif_cD)

%% 0.7 M - 25K points
k = 2;  % select second mach (0.7 Mach)

% select desired data 1trim/decimate data
wutDecimateFactor = 1;  % plot every ___ point
rcDecimateFactor = 10;


%wut data
wut_alpha = [Data.(mach{k}).wut.alt25.alpha_true_deg];
wut_cL = [Data.(mach{k}).wut.alt25.c_l];
wut_cD = [Data.(mach{k}).wut.alt25.c_d];
wutIndex = [1:wutDecimateFactor:length(wut_alpha)];

%rc data
rc_alpha = [Data.(mach{k}).rc.alt25.alpha_true_deg];
rc_cL = [Data.(mach{k}).rc.alt25.c_l];
rc_cD = [Data.(mach{k}).rc.alt25.c_d];
rcIndex = [1:rcDecimateFactor:length(rc_alpha)];


%%%%%%%%%% plot settings %%%%%%%%%
setFigDefaults; % A simple script to get fonts and font sizes ready
% CL vs alpha
f = figure('Units','inches')  ; % Instantiate a figure object
f.Position = [0 0 11 8.5]; % [x, y, width, height] in inches
hold on

% flight data
scatter(wut_alpha(wutIndex),wut_cL(wutIndex),'o',...
    'MarkerFaceColor','k','MarkerEdgeColor','k') %Wind Ups
scatter(rc_alpha(rcIndex),rc_cL(rcIndex),'s',...
    'MarkerEdgeColor','k') % Roller Coasters

% model data
plot(plot_aoas,cl_model_sub_plot, 'k','Linewidth',2)
plot(plot_aoas,cl_model_sub_minus, 'k:','Linewidth',1)
plot(plot_aoas,cl_model_sub_plus, 'k:','Linewidth',1)

title('Lift Curve - 0.7 Mach - 25,000 ft')
xlabel('Angle of Attack, $\alpha$ (deg)')
ylabel('Lift Coefficient, $C_L$')
axis([-5 30 -.2 1.6])
set(gca,'XMinorTick','on','YMinorTick','on','YAxisLocation','origin','XAxisLocation','origin')
legend('Wind Up Turn', 'Roller Coaster','Location','east');

% CL vs CD
f = figure('Units','inches')  ; % Instantiate a figure object
f.Position = [0 0 11 8.5]; % [x, y, width, height] in inches
hold on

%flight data
scatter(wut_cD(wutIndex),wut_cL(wutIndex),'o',...
    'MarkerFaceColor','k','MarkerEdgeColor','k') %Wind Ups
scatter(rc_cD(rcIndex),rc_cL(rcIndex),'s',...
    'MarkerEdgeColor','k') % Roller Coasters

% model data
plot(cd_model_pt7M_plot,plot_cls, 'k','Linewidth',2)
plot(cd_model_pt7M_minus,plot_cls, 'k:','Linewidth',1)
plot(cd_model_pt7M_plus,plot_cls, 'k:','Linewidth',1)

title('Drag Polar - 0.7 Mach - 25,000 ft')
xlabel('Drag Coefficient, $C_D$')
ylabel('Lift Coefficient, $C_L$')
axis([-.1 1 -.2 1.6])
set(gca,'XMinorTick','on','YMinorTick','on','YAxisLocation','origin','XAxisLocation','origin')
legend('Wind Up Turn', 'Roller Coaster','Location','east');

% Calculate average difference
cL = [rc_cL([200:1:end]); wut_cL];
cD = [rc_cD; wut_cD];
alpha= [rc_alpha; wut_alpha];

% reset diff values
dif_cL = zeros(1,length(cL));
dif_cD = zeros(1,length(cL));
for i=1:length(cL)
    dif_cL(i) = cl_model_sub(alpha(i)) - cL(i);
    dif_cD(i) = cd_model_pt7M(cL(i)) - cD(i);
end

avg_cL_7M_25 = mean(dif_cL)
avg_cD_7M_25 = mean(dif_cD)
%% 0.7 M - 30K points
k = 2;  % select second mach (0.7 Mach)

% select desired data 1trim/decimate data
wutDecimateFactor = 8;  % plot every ___ point
rcDecimateFactor = 7;
splitDecimateFactor = 2;

%wut data
wut_alpha = Data.(mach{k}).wut.alt30.alpha_true_deg;
wut_cL = Data.(mach{k}).wut.alt30.c_l;
wut_cD = Data.(mach{k}).wut.alt30.c_d;
wutIndex = [1:wutDecimateFactor:length(wut_alpha)];

%rc data
rc_alpha = [Data.(mach{k}).rc.alt30.alpha_true_deg];
rc_cL = [ Data.(mach{k}).rc.alt30.c_l];
rc_cD = [Data.(mach{k}).rc.alt30.c_d];
rcIndex = [1:rcDecimateFactor:length(rc_alpha)];

% split data
split_alpha = [Data.(mach{k}).split.alt30.alpha_true_deg];
split_cL = [Data.(mach{k}).split.alt30.c_l];
split_cD = [Data.(mach{k}).split.alt30.c_d];
splitIndex = [1:splitDecimateFactor:length(split_alpha)];

%%%%%%%%%% plot settings %%%%%%%%%

setFigDefaults; % A simple script to get fonts and font sizes ready
% CL vs alpha
f = figure('Units','inches')  ; % Instantiate a figure object
f.Position = [0 0 11 8.5]; % [x, y, width, height] in inches
hold on

% flight data
scatter(wut_alpha(wutIndex),wut_cL(wutIndex),'o',...
    'MarkerFaceColor','k','MarkerEdgeColor','k') %Wind Ups
scatter(rc_alpha(rcIndex),rc_cL(rcIndex),'s',...
    'MarkerEdgeColor','k') % Roller Coasters
scatter(split_alpha(splitIndex),split_cL(splitIndex),'^',...
    'MarkerEdgeColor','k') % Split S

% model data
plot(plot_aoas,cl_model_sub_plot,'k','Linewidth',2)
plot(plot_aoas,cl_model_sub_minus,'k:','Linewidth',1)
plot(plot_aoas,cl_model_sub_plus,'k:','Linewidth',1)

title('Lift Curve - 0.7 Mach - 30,000 ft')
xlabel('Angle of Attack, $\alpha$ (deg)')
ylabel('Lift Coefficient, $C_L$')
axis([-5 30 -.2 1.6])
set(gca,'XMinorTick','on','YMinorTick','on','YAxisLocation','origin','XAxisLocation','origin')
legend('Wind Up Turn', 'Roller Coaster','Split S','Location','east');

% CL vs CD
f = figure('Units','inches')  ; % Instantiate a figure object
f.Position = [0 0 11 8.5]; % [x, y, width, height] in inches
hold on

%flight data
scatter(wut_cD(wutIndex),wut_cL(wutIndex),'o',...
    'MarkerFaceColor','k','MarkerEdgeColor','k') %Wind Ups
scatter(rc_cD(rcIndex),rc_cL(rcIndex),'s',...
    'MarkerEdgeColor','k') % Roller Coasters
scatter(split_cD(splitIndex),split_cL(splitIndex),'^',...
    'MarkerEdgeColor','k') % Split S

% model data
plot(cd_model_pt7M_plot,plot_cls, 'k','Linewidth',2)
plot(cd_model_pt7M_minus,plot_cls, 'k:','Linewidth',1)
plot(cd_model_pt7M_plus,plot_cls, 'k:','Linewidth',1)

title('Drag Polar - 0.7 Mach - 30,000 ft')
xlabel('Drag Coefficient, $C_D$')
ylabel('Lift Coefficient, $C_L$')
axis([-.1 1 -.2 1.6])
set(gca,'XMinorTick','on','YMinorTick','on','YAxisLocation','origin','XAxisLocation','origin')
legend('Wind Up Turn', 'Roller Coaster','Split S','Location','east');


% Calculate average difference
cL = [rc_cL; wut_cL; split_cL];
cD = [rc_cD; wut_cD; split_cD];
alpha= [rc_alpha; wut_alpha; split_alpha];

% reset diff values
dif_cL = zeros(1,length(cL));
dif_cD = zeros(1,length(cL));
for i=1:length(cL)
    dif_cL(i) = cl_model_sub(alpha(i)) - cL(i);
    dif_cD(i) = cd_model_pt7M(cL(i)) - cD(i);
end

avg_cL_7M_30 = mean(dif_cL)
avg_cD_7M_30 = mean(dif_cD)

%% 1.1 M, 25K
k = 3;  % select third mach (1.1 Mach)

% select desired data 1trim/decimate data
wutDecimateFactor = 2;  % plot every ___ point
rcDecimateFactor = 10;


%wut data
wut_alpha = [Data.(mach{k}).wut.alt25.alpha_true_deg];
wut_cL = [Data.(mach{k}).wut.alt25.c_l];
wut_cD = [Data.(mach{k}).wut.alt25.c_d];
wutIndex = [1:wutDecimateFactor:length(wut_alpha)];

%rc data
rc_alpha = [Data.(mach{k}).rc.alt25.alpha_true_deg];
rc_cL = [Data.(mach{k}).rc.alt25.c_l];
rc_cD = [Data.(mach{k}).rc.alt25.c_d];
rcIndex = [1:rcDecimateFactor:length(rc_alpha)];

%%%%%%%%%% plot settings %%%%%%%%%

setFigDefaults; % A simple script to get fonts and font sizes ready
% CL vs alpha
f = figure('Units','inches')  ; % Instantiate a figure object
f.Position = [0 0 11 8.5]; % [x, y, width, height] in inches
hold on

% flight data
scatter(wut_alpha(wutIndex),wut_cL(wutIndex),'o',...
    'MarkerFaceColor','k','MarkerEdgeColor','k') %Wind Ups
scatter(rc_alpha(rcIndex),rc_cL(rcIndex),'s',...
    'MarkerEdgeColor','k') % Roller Coasters

% model data
plot(plot_aoas,cl_model_super_plot, 'k','Linewidth',2)
plot(plot_aoas,cl_model_super_minus, 'k:','Linewidth',1)
plot(plot_aoas,cl_model_super_plus, 'k:','Linewidth',1)

title('Lift Curve - 1.1 Mach - 25,000 ft')
xlabel('Angle of Attack, $\alpha$ (deg)')
ylabel('Lift Coefficient, $C_L$')
axis([-2 12 -.1 1])
set(gca,'XMinorTick','on','YMinorTick','on','YAxisLocation','origin','XAxisLocation','origin')
legend('Wind Up Turn', 'Roller Coaster','Location','east');

% CL vs CD
f = figure('Units','inches')  ; % Instantiate a figure object
f.Position = [0 0 11 8.5]; % [x, y, width, height] in inches
hold on

%flight data
scatter(wut_cD(wutIndex),wut_cL(wutIndex),'o',...
    'MarkerFaceColor','k','MarkerEdgeColor','k') %Wind Ups
scatter(rc_cD(rcIndex),rc_cL(rcIndex),'s',...
    'MarkerEdgeColor','k') % Roller Coasters

% model data
plot(cd_model_super_plot,plot_cls, 'k','Linewidth',2)
plot(cd_model_super_minus,plot_cls, 'k:','Linewidth',1)
plot(cd_model_super_plus,plot_cls, 'k:','Linewidth',1)

title('Drag Polar - 1.1 Mach - 25,000 ft')
xlabel('Drag Coefficient, $C_D$')
ylabel('Lift Coefficient, $C_L$')
axis([0 0.25 -.1 1])
set(gca,'XMinorTick','on','YMinorTick','on','YAxisLocation','origin','XAxisLocation','origin')
legend('Wind Up Turn', 'Roller Coaster','Location','east');

% Calculate average difference
cL = [rc_cL; wut_cL];
cD = [rc_cD; wut_cD];
alpha= [rc_alpha; wut_alpha];

% reset diff values
dif_cL = zeros(1,length(cL));
dif_cD = zeros(1,length(cL));
for i=1:length(cL)
    dif_cL(i) = cl_model_super(alpha(i)) - cL(i);
    dif_cD(i) = cd_model_pt_super(cL(i)) - cD(i);
end

avg_cL_11M_25 = mean(dif_cL([1:373,436:end]))
avg_cD_11M_25 = mean(dif_cD([1:373,436:end]))

%% 1.1 M, 30K
k = 3;  % select third mach (1.1 Mach)

% select desired data 1trim/decimate data
wutDecimateFactor = 8;  % plot every ___ point
rcDecimateFactor = 10;
splitDecimateFactor = 2;

%wut data
wut_alpha = [Data.(mach{k}).wut.alt30.alpha_true_deg];
wut_cL = [Data.(mach{k}).wut.alt30.c_l];
wut_cD = [Data.(mach{k}).wut.alt30.c_d];
wutIndex = [1:wutDecimateFactor:length(wut_alpha)];

%rc data
rc_alpha = [Data.(mach{k}).rc.alt30.alpha_true_deg];
rc_cL = [Data.(mach{k}).rc.alt30.c_l];
rc_cD = [Data.(mach{k}).rc.alt30.c_d];
rcIndex = [1:rcDecimateFactor:length(rc_alpha)];

% split data
split_alpha = [Data.(mach{k}).split.alt30.alpha_true_deg];
split_cL = [Data.(mach{k}).split.alt30.c_l];
split_cD = [Data.(mach{k}).split.alt30.c_d];
splitIndex = [1:splitDecimateFactor:length(split_alpha)];

%%%%%%%%%% plot settings %%%%%%%%%

setFigDefaults; % A simple script to get fonts and font sizes ready
% CL vs alpha
f = figure('Units','inches')  ; % Instantiate a figure object
f.Position = [0 0 11 8.5]; % [x, y, width, height] in inches
hold on

% flight data
scatter(wut_alpha(wutIndex),wut_cL(wutIndex),'o',...
    'MarkerFaceColor','k','MarkerEdgeColor','k') %Wind Ups
scatter(rc_alpha(rcIndex),rc_cL(rcIndex),'s',...
    'MarkerEdgeColor','k') % Roller Coasters
scatter(split_alpha(splitIndex),split_cL(splitIndex),'^',...
    'MarkerEdgeColor','k') % Split S

% model data
plot(plot_aoas,cl_model_super_plot,'k','Linewidth',2)
plot(plot_aoas,cl_model_super_minus,'k:','Linewidth',1)
plot(plot_aoas,cl_model_super_plus,'k:','Linewidth',1)

title('Lift Curve - 1.1 Mach - 30,000 ft')
xlabel('Angle of Attack, $\alpha$ (deg)')
ylabel('Lift Coefficient, $C_L$')
axis([-2 12 -.1 1])
set(gca,'XMinorTick','on','YMinorTick','on','YAxisLocation','origin','XAxisLocation','origin')
legend('Wind Up Turn', 'Roller Coaster','Split S','Location','east');

% CL vs CD
f = figure('Units','inches')  ; % Instantiate a figure object
f.Position = [0 0 11 8.5]; % [x, y, width, height] in inches
hold on

%flight data
scatter(wut_cD(wutIndex),wut_cL(wutIndex),'o',...
    'MarkerFaceColor','k','MarkerEdgeColor','k') %Wind Ups
scatter(rc_cD(rcIndex),rc_cL(rcIndex),'s',...
    'MarkerEdgeColor','k') % Roller Coasters
scatter(split_cD(splitIndex),split_cL(splitIndex),'^',...
    'MarkerEdgeColor','k') % Split S

% model data
plot(cd_model_super_plot,plot_cls, 'k','Linewidth',2)
plot(cd_model_super_minus,plot_cls, 'k:','Linewidth',1)
plot(cd_model_super_plus,plot_cls, 'k:','Linewidth',1)

title('Drag Polar - 1.1 Mach - 30,000 ft')
xlabel('Drag Coefficient, $C_D$')
ylabel('Lift Coefficient, $C_L$')
axis([0 0.25 -.1 1])
set(gca,'XMinorTick','on','YMinorTick','on','YAxisLocation','origin','XAxisLocation','origin')
legend('Wind Up Turn', 'Roller Coaster','Split S','Location','east');

% Calculate average difference
cL = [rc_cL; wut_cL; split_cL];
cD = [rc_cD; wut_cD; split_cD];
alpha= [rc_alpha; wut_alpha; split_alpha];

% reset diff values
dif_cL = zeros(1,length(cL));
dif_cD = zeros(1,length(cL));
for i=1:length(cL)
    dif_cL(i) = cl_model_super(alpha(i)) - cL(i);
    dif_cD(i) = cd_model_pt_super(cL(i)) - cD(i);
end

avg_cL_11M_30 = mean(dif_cL)
avg_cD_11M_30 = mean(dif_cD)
