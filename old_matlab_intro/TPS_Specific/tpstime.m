function tout=tpstime(time,numsig)
%TPSTIME Convert seconds to IRIG or IRIG to seconds
%
%       tout = tpstime(tin)
%       tout = tpstime(tin,numsig)
%
%   tin    - time in seconds after 12:00 am 1 Jan of this year
%            or, IRIG as ddd:hh:mm:ss.sss
%   numsig - number of decimals seconds, default is 3, e.g. ss.sss
%   tout   - input must be ddd:hh:mm:ss.sss or ddd hh:mm:ss.sss as a 
%            string array or cell, which is converted to seconds
%
% Example:
%   tsec  = tpstime('000:01:00:02.003') % produces 3602.003
%   tirig = tpstime(tsec) % produces '000:01:00:02.003'
%           3602.003
%
% written by: Maj Tim Jorris, TPS/CS, Jan 2009
%   Bug identified: day is off by 1, e.g. 1 Jan = 000, fixed (12 Jan 2011)

Jan_1=1; % set to 1 for Jan 1st equal 1, set to 0 if '000:00:00:00.000'=0

if length(time)==1 && ishandle(time) &&  mod(time,1)~=0 
    % User has provide an axis or label, e.g. get(gca,'xlabel')
    %
    % The mod(time,1) is to eliminate integers, Figure 1 could be valid but
    % the user is more likely to be trying to convert 1 to IRIG
    %
    % It is extremely unlikely that a user's time happen to equal to a
    % handle, but the length(time)==1 is used to at least lower the chance.

    switch get(time,'Type')
        case 'axes' % assume the x-axis, who would put time on the y-axis
            Ha=time;
        otherwise
            error('Time has matched a handle. Use a vector of time instead')
    end
    if nargin >= 2 && numsig==0
        kids=findobj(Ha,'Type','line');
        for i=1:length(kids)
        % Zero out the x-axis, time=0;
        kiddie=kids(i);
        xdata=get(kiddie,'XData');
        Udata=get(Ha,'UserData');
        if xdata(1)==0 && ~isempty(Udata)
            % Turn normalized back to unnormalize
            if isnumeric(Udata)
                xdata=xdata+Udata;
            end
        elseif xdata(1)~=0
            % Subtract first time
            t0=xdata(1);
            xdata=xdata-t0;
            if i==1
                set(Ha,'UserData',t0)
            end
        else
            return
        end
        set(kiddie,'Xdata',xdata)
        end
        return
    end
    tnum=str2num(get(Ha,'XTickLabel'));
    all_labels=get(Ha,'XTickLabel');
    
	if isempty(all_labels) || ~isempty(findstr(all_labels(1,:),':'))
        % It's a string (IRIG) so convert to time in seconds
        set(Ha,'XTickLabelMode','auto')
        % tick_num=get(gca,'XTick');
%         if size(tick_num,1)==1
%             tick_num=tick_num';
%         end
%         % t_temp=num2str(tick_num);
        return
    else
        t_temp=tpstime(get(Ha,'XTick')); % XTick has the real numbers
        % To have worked correctly, and gotten here, this gave ddd:hh:mm:ss.???
        % Thus, remove the days since they take up too much room
        t_temp(:,1:4)=[];
        % There's usually still not enough room, so just pick every other one
        len=size(t_temp,1);
        if len > 2
            t_blank=char(t_temp*0+32); % All blanks
            if nargin < 2, numsig=2; end
            for i=1:numsig:len
                    t_blank(i,:)=t_temp(i,:); % fill only non-skipped with numbers
            end
            t_temp=t_blank; % Use the partially filled below
        end
    end
    h = Ha;
    Hf=get(Ha,'Parent');
    ha=findobj(Hf,'Type','axes');
    if length(ha)==2 && sum(get(ha(1),'Pos')-get(ha(2),'Pos'))<1e-3
        % It's plotyy plot
        t_blank=char(t_temp*0+32); % All blanks
        if strcmp(get(ha(1),'YAxisLocation'),'right')
            h_front_trans_right=ha(1);
            h_back_white_left=ha(2);
        else
            h_front_trans_right=ha(2);
            h_back_white_left=ha(1);
        end
        axes(h_front_trans_right) % put transparent left in front
        % linkaxes(ha,'x') % lock the x-axis only for zooming
        % The back owns the x labels
        set(h_back_white_left,'XTickLabelMode','auto','XTickLabel',t_blank)
        set(h_front_trans_right,'XTickLabelMode','auto','XTickLabel',t_temp)
        return
    end
    set(h,'XTickLabelMode','auto','XTickLabel',t_temp)
    return
elseif isnumeric(time)
    % convert seconds to ddd:hh:mm:ss.sss
    day=floor(time/86400);                       % days
    hrs=floor((time-day*86400)/3600);            % hours
    min=floor((time-day*86400-hrs*3600)/60);     % minutes
    sec=time-day*86400-hrs*3600-min*60;          % seconds
    n=length(time);                              % length
    % Max dimension for days
    m=floor(log10(max(day)))+1; m=max(m,3); % will make bigger not smaller
    % sday=reshape(sprintf('%03d:' ,day),4,n)';    % string days
    dfmt=['%0',sprintf('%d',m),'d:'];
    sday=reshape(sprintf(dfmt,day+Jan_1),m+1,n)';    % string days  %% Add 1
    shrs=reshape(sprintf('%02d:' ,hrs),3,n)';    % string hours
    smin=reshape(sprintf('%02d:' ,min),3,n)';    % string minutes
    if nargin < 2, numsig=3;  % default decimals of seconds
    elseif ~isnumeric(numsig), error('Second input must be a number')
    elseif numsig < 1,     error('Number of decimals must be 1 or greater')
    end         
    secwid=numsig+3;
    secfmt=sprintf('%%0%d.%df',secwid,numsig); % second format string
    ssec=reshape(sprintf(secfmt,sec),secwid,n)'; % string seconds
    tout=[sday,shrs,smin,ssec];                  % all together
elseif ischar(time) || iscell(time)
    % TPS has 3 primary formats
    % 'ddd:hh:mm:ss.sss' 'ddd:hh:mm:ss.ssssss' and 'dd hh:mm:ss.sss'
    % So the parcing will provide a dynamic means of reading in these time
    % formats. Leading spaces will also be handled, '  dd hh:mm:ss.sss'
    if iscellstr(time) % Ensure we have a string matrix, not a cell array
        time=char_right(time);              
    end        
    % Parce the time format. Looking for ':' or ' ' delimiters, not leading
    time1=time(1,:);    % first number to perform testing
    [d1,d2,h1,h2,m1,m2,s1,dfmt,hfmt,mfmt,sfmt]=find_locations(time1);
    % With locations, start reading the time string array
    tfmt=['%',num2str(d2-d1+1),'d'];
    day=sscanf(time(:,d1:d2)',dfmt)-Jan_1;     % days  %% Add 1 mod so 1 Jan == 001 instead of 000
    hrs=sscanf(time(:,h1:h2)',hfmt);      % hours
    min=sscanf(time(:,m1:m2)',mfmt);      % minutes
    sec=sscanf(time(:,s1:end)',sfmt);     % seconds (good, handles ss.sss or ss.ssssss
    tout=day*86400+hrs*3600+min*60+sec;   % all together
end

function [d1,d2,h1,h2,m1,m2,s1,dfmt,hfmt,mfmt,sfmt]=find_locations(time1)
%FIND_LOCATIONS find start and stop locations for day, hr, min, and sec
%
% There should be a better way, but sometimes brute force just works
%
% written by: Maj Tim Jorris, TPS/CS, Mar 2009

len=length(time1);  % length of a time string
% Find location of first number, '  77 10:34:38.063' would be 3
for i=1:len
    if ~isempty(sscanf(time1(i),'%d'))
        firstnum=i; break
    end
    if i==len, error('No numbers were found within time string'), end
end
% Now find sets of numbers separated by sets of ' ' or ':'
prev_num=false; % previous found a number
prev_del=false; % previous found a delimiter
found_num=0;    % how many sets of number have been found
for i=firstnum:len
    if ~isempty(sscanf(time1(i),'%d')) % found a number
        if ~prev_num % first number in series
            found_num=found_num+1;
            prev_num=true;
            switch found_num
                case 1
                    d1=i;
                case 2
                    h1=i;
                case 3
                    m1=i;
                case 4
                    s1=i;
            end
        end
        prev_del=false; % previous was a number, not a delimiter
    elseif strcmp(time1(i),' ') || strcmp(time1(i),':') % found a delimiter
        if ~prev_del  % first delimiter in series
            prev_del=true;
            prev_num=false; % previous was a delimiter, not a number
            switch found_num 
                case 1
                    d2=i-1;
                case 2
                    h2=i-1;
                case 3
                    m2=i-1;
            end
        end        
    end
end
if ~exist('d2','var') || ...
   ~exist('d1','var') || ...
   ~exist('h2','var') || ...
   ~exist('h1','var') || ...
   ~exist('m2','var') || ...
   ~exist('m1','var') || ...
   ~exist('s1','var')
    error(['String ''',time1,''' does not have the correct ddd:hh:mm:ss.sss or similar format'])
end
% Compute formats for the strings
dfmt=['%',num2str(d2-d1+1) ,'d'];  % simply '%d' won't work for vectors
hfmt=['%',num2str(h2-h1+1) ,'d'];
mfmt=['%',num2str(m2-m1+1) ,'d'];
% sec=sscanf(time(:,11:end)','%6f');  % bad, forces ss.sss
% sec=sscanf(time(:,11:end)','%f');   % bad, turns 1.5 to 1.50000041
sfmt=['%',num2str(len-s1+1),'f'];       % e.g. '%6f' for ss.sss

function str=char_right(tcel)
% Convert time cell into str array that has numbers right justified
%
% tcel=[
%     '7 15:31:19.403'
%     '77 15:31:19.403'
%     '77 15:31:19.416'
%     '257 15:33:19.469'
%     '257 15:33:19.481'
%     '257 15:33:19.493']
%
% char(tcel) will have blanks at the end, which will error our reading
% since the days, hr, min, seconds are not lined up. So, we will line them
% up by right justifying the string array.
%
% written by: Maj Tim Jorris, TPS/CS, Mar 2009
str=char(tcel);
id=str(:,end)==32; % a blank on the right
while sum(id) > 0
    str(id,:)=[str(id,end),str(id,1:end-1)]; % move right blank to front
    id=str(:,end)==32;                       % a blank on the right
end


