function vals_out = ucon(varargin)
% UCON- Units CONversion - Performs unit conversion
%
% Syntax:
%   VALS_OUT = ucon(STR_UNITS_FROM,STR_UNITS_TO)
%   VALS_OUT = ucon(VALS_IN,STR_UNITS_FROM,STR_UNITS_TO)
%
% Description:
%   VALS_OUT = ucon(STR_UNITS_FROM,STR_UNITS_TO) output
%       is a multiplication conversion factor
%   VALS_OUT = ucon(VALS_IN,STR_UNITS_FROM,STR_UNITS_TO)
%       outputs value(s) are converted values of VALS_IN
%
% Inputs:
%   STR_UNITS_FROM (REQUIRED)  String - Describes the units that the value
%                              is converted "from"
%   STR_UNITS_TO   (REQUIRED)  String - Describes the units that the value
%                              is converted "to"
%   VALS_IN        (OPTIONAL)  Value(s) to be converted
%
% Outputs:
%   VALS_OUT       Conversion factor of converted value
%
% Examples:
%   ucon('HR','SEC')     % equals 3600
%   ucon(120,'MIN','HR') % equals 2
%
% Dependencies:
%   NONE; 
%   for 'nd' the global variable CONST must be defined
%           .scale.len - length must be in units km
%           .scale.acc - acceleration must be in units km/s^2
%           .scale.rho - density must be in kg/m^3
%           .scale.qs  - heat flux must be in MJ_M2_SEC
% Comments:
%   All case of sec an single s will also work
%   If using 'nd'; CONST.scale.len and CONST.scale.acc are required
%        
% References:
%   Taylor, Barry N., Guide for the Use of the International System of
%       Units (SI), National Institute of Standards and Technology
%       Special Publication 811, Physics Laboratory, National Institute
%       of Standards and Technology, Gaithersburg, MD.
%
% Version History:
%   06-26-2008  Tim Jorris, TPS, U.S. Air Force
%               - can convert to/from non-dimensional ('nd') if global
%                 global variable CONST.H0 must be provided in km
%                 H0 is geometric height above sea level
%                 CONST.H0=ucon(100000,'ft','km'); % would work fine
%                 CONST.R0=6378; CONST.G0=9.81; % must be set
%                 go=ucon(1,'nd','km_sec2'); % 1 accel unit
%                 ro=ucon(1,'nd','km');      % 1 length unit
%                 CONST.H0=0;
%                 R0=ucon(1,'nd','km'); % radius of the Earth in use
%   01-14-2007  Tim Jorris, AFIT, U.S. Air Force
%               -s modified help to include available units
%               - switch the order of input, more intuitive to me
%   04-25-2002  John Bourgeois, AFFTC, U.S. Air Force
%
%
%       RECOGNIZED UNITS
%   Temperature
%       K,C,R,F
%   Acceleration
%       FT_SEC2,M_SEC2,KM_SEC2,ND
%   Angle
%       DEG,RAD
%   Angular Acceleration
%       DEG_SEC2,RAD_SEC2
%   Angular Momentum
%       SLUGFT2_SEC,KGM2_SEC
%   Anglular Momentum Rate
%       SLUGFT2_SEC2,KGM2_SEC2
%   Angular Velocity
%       DEG_SEC,RAD_SEC,RPM
%   Area
%       FT2,M2,IN2,KM2
%   Capacity
%       GAL,LIT
%   Capacity Flow
%       GAL_SEC,LIT_SEC
%   Coordinates
%       DEG,DEGMIN,DMS
%   Density
%       SLUG_FT3,KG_M3,KG_KM3
%   Energy/Work
%       FTLB,J,BTU
%   Force
%       LB,N,KGKM_SEC
%   Heat Flux
%       BTU_FT2_SEC,J_M2_SEC,MJ_M2_SEC
%   Heat Load
%       BTU_FT2,J_M2,MJ_M2
%   Length
%       FT,M,NMI,KM,SMI,ARCDEG,ARCRAD,ND (1 ARCDEG = 60 NMI)
%   Mass
%       SLUG,KG,LB (assumes g=32.174 ft/s^2)
%   Mass Flow
%       SLUG_SEC,KG_SEC
%   Moment and Product of Inertia
%       SLUGFT2, KGM2
%   Power
%       FTLB_SEC,W,HP
%   Pressure
%       LB_FT2,N_M2,PA,KG_KMSEC2
%   Pressure Rate
%       LB_FT2_SEC,N_M2_SEC
%   Time
%       SEC,HR,MIN,ND
%   Torque
%       LBFT,NM
%   Velocity (Airspeed)   
%       FT_SEC,M_SEC,KM_HR,KTS,KM_SEC,ND
%   Volume
%       FT3,M3
%   Volumetric Flow
%       FT3_SEC,M3_SEC
%   Others
%       FT2_SEC2_K,M2_SEC2_K (Specific Gas Constant)
%
%***********************************************************************
% UTILITY FUNCTION USED IN 412TW/ENTT MATLAB TOOLBOXES - DO NOT MODIFY *
%***********************************************************************

% function vals_out = funUtils_ConvertUnits(str_units_from,str_units_to,vals_in)

% Check number of inputs
error(nargchk(2,3,nargin))

% Assign Input Variables
if nargin==2    % Unit ratio only
    str_units_from =varargin{1};
    str_units_to   =varargin{2};
else 
    vals_in        =varargin{1};
    str_units_from =varargin{2};
    str_units_to   =varargin{3};
end   

% Let FT_S be the same as FT_SEC, KMS2 is KMSEC2, S to SEC
for i=1:2
    if i==1, test_str=str_units_from; else, test_str=str_units_to; end
    found_s=strfind(upper(test_str),'_S');
    if isempty(found_s), found_s=strfind(upper(test_str),'KMS')+1; end
    if isempty(found_s) && length(test_str)==1 && strcmpi(test_str,'S'), found_s=0; end
    if ~isempty(found_s) && ((length(test_str) > found_s+1 && ...
       ~strcmpi('E',test_str(found_s+2))) || length(test_str)==found_s+1)
       % Found _S and next letter is not E, thus we have _S or _S2
       test_str=[test_str(1:found_s+1),'EC',test_str(found_s+2:end)];
    end
    if i==1, str_units_from=test_str; else, str_units_to=test_str; end
end

% Memory allocation
list_units_coord = cell(3,2);
list_units_temp = cell(12,2);
list_units = cell(71,3);
i=0;
%   Coordinates %       DEG,DEGMIN,DMS
i=i+1;list_units_coord(i,:) = {'DEG','DEGMIN'};
i=i+1;list_units_coord(i,:) = {'DEG','DMS'};
i=i+1;list_units_coord(i,:) = {'DEGMIN','DMS'};

% Temperature
list_units_temp(1,:)  = {'K','C'};
list_units_temp(2,:)  = {'K','F'};
list_units_temp(3,:)  = {'K','R'};
list_units_temp(4,:)  = {'C','K'};
list_units_temp(5,:)  = {'C','F'};
list_units_temp(6,:)  = {'C','R'};
list_units_temp(7,:)  = {'F','K'};
list_units_temp(8,:)  = {'F','C'};
list_units_temp(9,:)  = {'F','R'};
list_units_temp(10,:) = {'R','K'};
list_units_temp(11,:) = {'R','F'};
list_units_temp(12,:) = {'R','C'};

i  = 1;

% Acceleration
i=i+1;list_units(i,:) = {'FT_SEC2','M_SEC2',0.3048};
i=i+1;list_units(i,:) = {'FT_SEC2','KM_SEC2',0.3048/1000};
i=i+1;list_units(i,:) = {'M_SEC2','KM_SEC2',1/1000};
units_accel={'FT_SEC2','M_SEC2','KM_SEC2'};

% Angle
i=i+1;list_units(i,:) = {'DEG','RAD',pi/180};
units_angle={'DEG','RAD'};

% Angular Acceleration
i=i+1;list_units(i,:) = {'DEG_SEC2','RAD_SEC2',pi/180};

% Angular Momentum
i=i+1;list_units(i,:) = {'SLUGFT2_SEC','KGM2_SEC',14.59390*0.3048^2};

% Angular Momentum Rate
i=i+1;list_units(i,:) = {'SLUGFT2_SEC2','KGM2_SEC2',14.59390*0.3048^2};

% Angular Velocity
i=i+1;list_units(i,:) = {'DEG_SEC','RAD_SEC',pi/180};
i=i+1;list_units(i,:) = {'DEG_SEC','RPM',1/6};
i=i+1;list_units(i,:) = {'RAD_SEC','RPM',60/(2*pi)};

% Area
i=i+1;list_units(i,:) = {'FT2','M2',0.3048^2};
i=i+1;list_units(i,:) = {'IN2','M2',0.3048^2/12^2};
i=i+1;list_units(i,:) = {'IN2','KM2',0.3048^2/12^2/1000^2};
i=i+1;list_units(i,:) = {'KM2','M2',1000^2};
i=i+1;list_units(i,:) = {'FT2','KM2',0.3048^2/1000^2};

% Capacity
i=i+1;list_units(i,:) = {'GAL','LIT',3.785411784};

% Capacity Flow
i=i+1;list_units(i,:) = {'GAL_SEC','LIT_SEC',3.785411784};

% Density
i=i+1;list_units(i,:) = {'SLUG_FT3','KG_M3',14.59390/0.3048^3};
i=i+1;list_units(i,:) = {'SLUG_FT3','KG_KM3',14.59390/0.3048^3*1000^3};
i=i+1;list_units(i,:) = {'KG_M3','KG_KM3',1000^3};
units_density={'SLUG_FT3','KG_M3','KM_KM3'};
    
% Energy/Work
i=i+1;list_units(i,:) = {'FTLB','J',14.59390*0.3048^2};
i=i+1;list_units(i,:) = {'BTU','J',1054.35026444}; % exact 1054.35026444, POST 1054.3502
i=i+1;list_units(i,:) = {'BTU','MJ',1054.35026444*1e-6};

% Force
i=i+1;list_units(i,:) = {'LB','N',14.59390*0.3048};
i=i+1;list_units(i,:) = {'LB','KGKM_SEC',14.59390*0.3048/1000};
i=i+1;list_units(i,:) = {'N','KGKM_SEC',1/1000};

%   Heat Flux       BTU_FT2_SEC,J_M2_SEC,MJ_M2_SEC
i=i+1;list_units(i,:) = {'BTU_FT2_SEC','J_M2_SEC',1054.35026444/0.3048^2};
i=i+1;list_units(i,:) = {'BTU_FT2_SEC','MJ_M2_SEC',1054.35026444/0.3048^2*1e-6};
i=i+1;list_units(i,:) = {'J_M2_SEC','MJ_M2_SEC',1e-6};
units_heatflux={'BTU_FT2_SEC','J_M2_SEC','MJ_M2_SEC'};

%   Heat Load       BTU_FT2,J_M2,MJ_M2
i=i+1;list_units(i,:) = {'BTU_FT2','J_M2',1054.35026444/0.3048^2};
i=i+1;list_units(i,:) = {'BTU_FT2','MJ_M2',1054.35026444/0.3048^2*1e-6};
i=i+1;list_units(i,:) = {'J_M2','MJ_M2',1e-6};
units_heatload={'BTU_FT2','J_M2','MJ_M2'};

% Length
i=i+1;list_units(i,:) = {'FT','M' ,0.3048};
i=i+1;list_units(i,:) = {'FT','NMI',0.3048/1852};
i=i+1;list_units(i,:) = {'FT','KM',0.3048/1000};
i=i+1;list_units(i,:) = {'M' ,'NMI',1/1852};
i=i+1;list_units(i,:) = {'M' ,'KM',0.001};
i=i+1;list_units(i,:) = {'NMI','KM',1.852};
i=i+1;list_units(i,:) = {'FT','ARCDEG',0.3048/1852/60};
i=i+1;list_units(i,:) = {'M','ARCDEG',1/1852/60};
i=i+1;list_units(i,:) = {'KM','ARCDEG',1/1.852/60};
i=i+1;list_units(i,:) = {'NMI','ARCDEG',1/60};
i=i+1;list_units(i,:) = {'FT','ARCRAD',0.3048/1852/60*pi/180};
i=i+1;list_units(i,:) = {'M','ARCRAD',1/1852/60*pi/180};
i=i+1;list_units(i,:) = {'KM','ARCRAD',1/1.852/60*pi/180};
i=i+1;list_units(i,:) = {'NMI','ARCRAD',1/60*pi/180};
i=i+1;list_units(i,:) = {'ARCRAD','ARCDEG',180/pi};
i=i+1;list_units(i,:) = {'FT','SMI',1/5280};
i=i+1;list_units(i,:) = {'M','SMI',1/0.3048/5280};
i=i+1;list_units(i,:) = {'KM','SMI',1000/0.3048/5280};
i=i+1;list_units(i,:) = {'NMI','SMI',1852/0.3048/5280};
i=i+1;list_units(i,:) = {'ARCDEG','SMI',1/0.3048*1852*60/5280};
units_len={'FT','M','NMI','KM','ARCDEG','SMI'};
% Mass
i=i+1;list_units(i,:) = {'SLUG','KG',14.59390};
i=i+1;list_units(i,:) = {'LB','SLUG',1/32.174};
i=i+1;list_units(i,:) = {'LB','KG',1/32.174*14.59390};

% Mass Flow
i=i+1;list_units(i,:) = {'SLUG_SEC','KG_SEC',14.59390};

% Moment and Product of Inertia
i=i+1;list_units(i,:) = {'SLUGFT2','KGM2',14.59390*0.3048^2};

% Power
i=i+1;list_units(i,:) = {'FTLB_SEC','W',14.59390*0.3048^2};
i=i+1;list_units(i,:) = {'FTLB_SEC','HP',(14.59390*0.3048^2)/746};
i=i+1;list_units(i,:) = {'W','HP',1/746};

% Pressure
i=i+1;list_units(i,:) = {'LB_FT2','N_M2',14.59390/0.3048};
i=i+1;list_units(i,:) = {'LB_FT2','KG_KMSEC2',14.59390/0.3048*1000};
i=i+1;list_units(i,:) = {'N_M2','KG_KMSEC2',1000};
i=i+1;list_units(i,:) = {'LB_FT2','PA',14.59390/0.3048};
i=i+1;list_units(i,:) = {'PA','KG_KMSEC2',1000};
i=i+1;list_units(i,:) = {'N_M2','PA',1};
% Pressure rate
i=i+1;list_units(i,:) = {'LB_FT2_SEC','N_M2_SEC',14.59390/0.3048};

% Time
i=i+1;list_units(i,:)  = {'SEC','MIN',1/60};
i=i+1;list_units(i,:)  = {'SEC','HR' ,1/3600};
i=i+1;list_units(i,:)  = {'MIN','HR' ,1/60};
units_time={'SEC','MIN','HR'}; % add to this list if updated above

% Torque
i=i+1;list_units(i,:) = {'LBFT','NM',14.59390*0.3048^2};

% Velocity (Airspeed)
i=i+1;list_units(i,:) = {'FT_SEC','M_SEC',0.3048};
i=i+1;list_units(i,:) = {'FT_SEC','KTS'  ,(0.3048*3600)/1852};
i=i+1;list_units(i,:) = {'FT_SEC','KM_HR',(0.3048*3600)/1000};
i=i+1;list_units(i,:) = {'M_SEC' ,'KTS'  ,3600/1852};
i=i+1;list_units(i,:) = {'M_SEC' ,'KM_HR',3.6};
i=i+1;list_units(i,:) = {'KTS'   ,'KM_HR',1.852};
i=i+1;list_units(i,:) = {'FT_SEC','KM_SEC',0.3048/1000};
i=i+1;list_units(i,:) = {'M_SEC' ,'KM_SEC',1/1000};
i=i+1;list_units(i,:) = {'KTS'   ,'KM_SEC',1.852/3600};
units_vel={'FT_SEC','M_SEC','KTS','KM_HR','KM_SEC'};

% Volume
i=i+1;list_units(i,:) = {'FT3','M3',0.3048^3};

% Volumetric Flow
i=i+1;list_units(i,:) = {'FT3_SEC','M3_SEC',0.3048^3};

% Others
i=i+1;list_units(i,:) = {'FT2_SEC2_K','M2_SEC2_K',0.3048^2}; % Specific gas constant

if strcmpi(str_units_from,str_units_to)
    % "Units from" equal "Units to" 
    if nargin==2
        vals_out = 1;
    else
        vals_out = vals_in;
    end
else
    % Temperature
    ind_temp = find(strcmpi(str_units_from,list_units_temp(:,1)) & strcmpi(str_units_to,list_units_temp(:,2)));
    % Non-dimensionalization
    ind_nd   = strcmpi(str_units_from,'nd') || strcmpi(str_units_to,'nd');
    if ~isempty(ind_temp)
        if nargin==2
            switch ind_temp
                case 3   % {'K','R'}
                    vals_out = vals_in*(9/5);
                case 10  % {'R','K'}
                    vals_out = vals_in*(5/9);
                otherwise
                    error('The ''convert_units'' function does support an output conversion factor for between these temperature units.');
            end
        else
            switch ind_temp
                case 1   % {'K','C'}
                    vals_out = vals_in-273.15;
                case 2   % {'K','F'}
                    vals_out = (vals_in-273.15)*(9/5)+32;
                case 3   % {'K','R'}
                    vals_out = vals_in*(9/5);
                case 4   % {'C','K'}
                    vals_out = vals_in+273.15;
                case 5   % {'C','F'}
                    vals_out = vals_in*(9/5)+32;
                case 6   % {'C','R'}
                    vals_out = (vals_in+273.15)*(9/5);
                case 7   % {'F','K'}
                    vals_out = (5/9)*(vals_in-32)+273.15;
                case 8   % {'F','C'}
                    vals_out = (5/9)*(vals_in-32);
                case 9   % {'F','R'}
                    vals_out = vals_in+459.67;
                case 10  % {'R','K'}
                    vals_out = vals_in*(5/9);
                case 11  % {'R','F'}
                    vals_out = vals_in-459.67;
                case 12  % {'R','C'}
                    vals_out = vals_in*(5/9)-273.15;
            end
        end
    elseif ind_nd
        % Must lookfor and compute non-dimensional units
        % The global CONST must exist and field .H0 must be km
        global CONST
        if isempty(CONST)
            error('global variable CONST must be defined, and contain .scale')
        elseif ~isfield(CONST,'scale')
            error('global variable CONST must contain fieldname ''scale''')
        end
        %{
        H0=CONST.H0;    % Altitude above sea level   (km)
        R0=CONST.R0;    % Radius of the Earth (km)
        G0=CONST.G0;    % gravity at sea level (m/s^2)
        %R0 =6378;       % Earth radius               (km)
        %G0 =9.81;       % gravity at sea level    (m/s^2)
        %R0  = 6356.766;       % /* radius of Earth - km */
        %G0  = 9.80665;        % /* nominal gravitational acceleration - m/s^2  */
        % CONST.R0=R0; CONST.G0=G0;
        r0=R0+H0; g0=G0*(R0/r0)^2/1000;
        scale.len=r0;           % km
        scale.vel=sqrt(r0*g0);  % km/s
        scale.accel=g0;         % km/s^2
        scale.time=sqrt(r0/g0); % sec     
   %}
        % scale.len=CONST.scale.len; scale.acc=CONST.scale.acc;
        scale=CONST.scale;
        ro=scale.len; go=scale.acc; 
        scale.vel=sqrt(ro*go); scale.time=sqrt(ro/go);
        if strcmpi(str_units_to,'nd')
            lkfor=lower(str_units_from); invfun=@(x) x;
        else
            lkfor=lower(str_units_to);    invfun=@(x) inv(x);
        end
        % The default scale factor is from dimensional to non-dim
        % the invfun will simply flip the factor if swapped
        if ~isempty(strmatch(lkfor,lower(units_len),'exact'))
            scalef=ucon(lkfor,'km')/scale.len;
        elseif ~isempty(strmatch(lkfor,lower(units_vel),'exact'))
            scalef=ucon(lkfor,'km_sec')/scale.vel;
        elseif ~isempty(strmatch(lkfor,lower(units_accel),'exact'))
            scalef=ucon(lkfor,'km_sec2')/scale.accel;
        elseif ~isempty(strmatch(lkfor,lower(units_time),'exact'))
            scalef=ucon(lkfor,'sec')/scale.time;
        elseif ~isempty(strmatch(lkfor,lower(units_angle),'exact'))
            scalef=ucon(lkfor,'rad')/1; % 'rad' is non-dimensional
        elseif ~isempty(strmatch(lkfor,lower(units_density),'exact'))
            scalef=ucon(lkfor,'kg_m3')/scale.rho; 
        elseif ~isempty(strmatch(lkfor,lower(units_heatflux),'exact'))
            scalef=ucon(lkfor,'MJ_m2_sec')/scale.qs;
        elseif ~isempty(strmatch(lkfor,lower(units_heatload),'exact'))
            scalef=ucon(lkfor,'MJ_m2')/scale.qs/scale.time;
        else
            error(['Units ''',lkfor,''' not found'])
        end
        scalef=invfun(scalef);
        vals_out=vals_in*scalef;
    else
        % Everything else
        ind_mult = find(strcmpi(str_units_from,list_units(:,1)) & strcmpi(str_units_to,list_units(:,2)));
        ind_divi = find(strcmpi(str_units_from,list_units(:,2)) & strcmpi(str_units_to,list_units(:,1)));
        if ~isempty(ind_mult)
            if nargin==2
                vals_out = list_units{ind_mult,3};
            else
                vals_out = vals_in*list_units{ind_mult,3};
            end
        elseif ~isempty(ind_divi)
            if nargin==2
                vals_out = 1/list_units{ind_divi,3};
            else
                vals_out = vals_in/list_units{ind_divi,3};
            end
        else
            error('The ''convert_units'' function does not currently support this conversion.');
        end
    end
end