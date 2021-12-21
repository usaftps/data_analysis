function tsc=str2tsc(str,time_name)

%STR2TSC Convert a structure to a time series collection for use in tstool
%
%   tsc=str2tsc(str,time_name)
%
% str       - structure containing vectors of data sharing the same time 
% time_name - fieldnames that contains the desired time vector
% tsc       - time series collection with members from the structure
% 
% Example:
%   data.irig_time  = [69.01:.01:169];  % on time vector
%   data.delta_time = data.irig_time-data.irig_time(1); % starts at zero
%   data.costh      = cos(20*pi/180*data.delta_time);
%   data.sinth      = sin(40*pi/180*data.delta_time);
%
%   tsc=str2tsc(data,'irig_time');  % uses irig time as time vector
%   tsc=str2tsc(data,'delta_sec');  % uses time from zero as time vectord
%
% written by: Maj Tim Jorris, TPS/CS, Mar 2008
%
% See also TIMESERIES, TSCOLLECTION, TSTOOL

%% Set the time vector
name=inputname(1); if isempty(name), name='tsc'; end
if nargin < 2
    error('You must supply the name of the desired time vector')
end

%% Add StartDate
time=str.(time_name);
%% Remove bad times
kill=boolean(zeros(size(time)));
tgood=time(1);
for i=1:length(time)-1
    ti1=time(i+1);
    if ti1 > tgood
        tgood=ti1;
    else
        kill(i)=true;
    end
end, keep=~kill;

c=clock; year=c(1); mth=0; day=0; hr=0; min=0; sec=time(1); % floor(time(1));
if sec ~= 0
    tsc=tscollection(time(keep)-sec,'Name',name);
    tsc.TimeInfo.StartDate=datestr(datenum([year mth day hr min sec]),'dd-mmm-yyyy HH:MM:SS.FFF'); 
else
    tsc=tscollection(time(keep),'Name',name);
end

%% Add all of the time series
fdnames=fieldnames(str);
tlen=length(time);

for i=1:length(fdnames)
    % Verify the field is a column of data (same length as time)
    dat=double(str.(fdnames{i})); % xfl has non-doubles
    if strcmp(fdnames{i},time_name)
        continue  % Do Not Re-add Time
    elseif isnumeric(dat)  && length(dat)==tlen % Maybe another structure
        % ts =timeseries(dat(keep),time(keep),'Name',fdnames{i});
        tsc=addts(tsc,dat(keep),fdnames{i});
    else
        % continue % try the next field
        % Add to TimeInfo.UserData so nothing is lost       
        tsc.TimeInfo.UserData.(fdnames{i})=str.(fdnames{i});
    end
end
