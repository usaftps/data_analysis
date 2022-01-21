function data=tpsthin(data,id)
%TPSTHIN Thin (decimate) a structure of data by index provided
%
% newS=tpsthin(oldS,id)
%
% oldS - old structure. Should have fields with data e.g. .Time
% id   - index to retrieve from all fields within structure
% newS - new structure. Fields that are not a column of data are ignored
%
% Note: What about the reserve end word, e.g. 1:2:end won't have meaning as
% an argument ... unless it's provided as a string.
%
% Ex:
%       id=data.Time>tpstime('32:12:11:32.145'); % Time greater give IRIG 
%       data=tpsthin(data,id); % get just those time sliced for all vars
%
%       data=tpsthin(data,'1:20:end'); % reserve word end as string
%
% written by: Lt Col Tim Jorris, PhD, USAF
%             TPS/ED, May 2010

fn=fieldnames(data);
for i=1:length(data)
    for j=1:length(fn)
        fld=data(i).(fn{j});
        if isnumeric(fld) && ~isempty(fld) && min(size(fld))==1
            if isnumeric(id) || islogical(id)
                data(i).(fn{j})= data(i).(fn{j})(id);
            elseif ischar(id)
                data(i).(fn{j})=eval(['data(i).(fn{j})(',id,')']);
            else
                error('Index must be a vector or a string, [1:10] or ''1:5:end''')
            end
        end
    end
end
