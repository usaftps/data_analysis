function varargout = TPS_data_norm(varargin)
%TPS_data_norm M-file for TPS_data_norm.fig
%
%Just type 'TPS_data_norm' at the >> prompt to run the GUI.
%
%GUI Options:
%   Press "Select the Subject CSV File" to choose the CSV file with the
%   data.
%This file may come from ILIAD (T-38 or F-16) or the C-12 card reader
%utility. The file need not have text headers but if it does, it will
%identify the 'Delta_Irig' column from ILIAD files and use this time for
%the time data. C-12 files contain two types of date/time group and this
%program uses the ASCII time column to create a delta time column in
%seconds labeled 'DELTA_TIME.'
%
%   The processed output is re-formatted as a  MATLAB structure containing
%several fields. If requested by checking 'Create Separate Event
%Structures', a separate structure will be created for the duration of each
%event.* All of these structures are saved into a single MAT file with the
%specified name and location ('tpsid_' is attached to the beginning of the
%file name to signify that it is compatible with the data review utility.
%Each structure has the following fields:
%   date: The date and time the file was processed in MATLAB vector format.
%   subset: 'all_data' is all of the data. Each of the event segments is
%       saved as 'EC_XXX' where XXX is the event number.
%   time_vec: The data vector containing the time in seconds. If no time is
%       available or identified, this vector will contain the sample (row)
%       number.
%   event_col: If known, the column containing event numbers. If unknown,
%       this variable will contain -1.
%   vec_names: The vector (header names) corrected to conform to MATLAB
%       variable standards.
%   data: The data itself. Non-numerical data is converted to NaN.
%   num_vecs: The number of data vectors.
%   samples: The total number of time slices.
%   note: A text note of unlimited length.
%   samp_rate_ave: The average sample rate.
%   displayvecs: The five columns pre-selected for display in the data tool.
%   ylims: The YLims for use in the data tool.
%
%   If desired, the tool will automatically open the data review utility.
%the user must still select the desired file when the utility opens.
%
%*If an event number is not contiguous (occurs more than once in the data
%stream) all of the data associated with that number will be in one vector.

% Last Modified by GUIDE v2.5 01-Feb-2017 15:22:44

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @TPS_data_norm_OpeningFcn, ...
    'gui_OutputFcn',  @TPS_data_norm_OutputFcn, ...
    'gui_LayoutFcn',  [], ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before TPS_data_norm is made visible.
function TPS_data_norm_OpeningFcn(hObject, eventdata, handles, varargin) 

% Choose default command line output for TPS_data_norm
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);



% --- Outputs from this function are returned to the command line.
function varargout = TPS_data_norm_OutputFcn(hObject, eventdata, handles) %#ok<*INUSL>

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in select_file.
function select_file_Callback(hObject, eventdata, handles) %#ok<*DEFNU>

[handles.CSVFileName,handles.CSVPathName] = uigetfile('*.csv','Select the CSV File');
handles.CSV_file = [handles.CSVPathName handles.CSVFileName];
set(handles.csvfile,'String',handles.CSV_file);

guidata(hObject, handles);


% --- Executes on button press in go.
function go_Callback(hObject, eventdata, handles)

%No point in going on if there is no data or target.
if ~isfield(handles,'CSV_file') || ~isfield(handles,'MAT_file')
    warndlg('Enter CSV and MAT names first!','Missing subset name(s)...')
    return
end

%Sort out the data.
csv_to_structs(handles.CSV_file,handles.MAT_file,1,...
    get(handles.notein,'String'), get(handles.createSES,'Value'));

%Send to the data review function
if get(handles.openQDR,'Value') == 1
    TPS_data_utility; end


% --- Executes on button press in putfile.
function putfile_Callback(hObject, eventdata, handles)

%Get a file name and make sure it starts with tpsid_
[handles.MATFileName,handles.MATPathName] =...
    uiputfile('tpsid_*.mat','Select the CSV File',handles.CSVPathName);
checker = strfind(handles.MATFileName,'tpsid_');
if isempty(checker) || checker ~= 1
    handles.MATFileName = ['tpsid_' handles.MATFileName];
end
handles.MAT_file = [handles.MATPathName handles.MATFileName];
set(handles.matfile,'String',handles.MAT_file);

guidata(hObject, handles);


% --- Executes on button press in quit.
function quit_Callback(hObject, eventdata, handles)

close(handles.figure1)


function csv_to_structs(csv_data,mat_data,split,note,events)

%The BIG function...

stat = msgbox('Reading CSV file for conversion...','Progress');

%Find the number of rows in the file
fid_in = fopen(csv_data,'r');
firstcol = textscan(fid_in, '%c%*[^\n]');
fclose(fid_in);
totrows=size(firstcol{1,1},1)-1;
clear firstcol;

%In this application, split is always 1, but in the future it might be
%advantageous to let the user choose how many rows per data read.
if split == 1
    split = round((totrows-1)/4);
    if split < 100
        split=100;
    else
        if split > 20000
            split = 20000;
        end
    end
end
iterations=round((totrows-1)/split+.5); %The number of data reads required

%Get to work... all_data is the structure that will contain the data. We
%start with the full data structure.

all_data.date = mat2str(clock);
all_data.subset = 'all_data';

%open the csv file for reading
fid_in = fopen(csv_data);

%Read in the first row of data (assumed vector names)
C = textscan(fid_in, '%s',1, 'delimiter','\r');
d_names = strread(C{1,1}{1,:},'%s','delimiter',',')'; %read vector names

%Initialize some variables
save_names = []; %This will be a vector of column names
ts_format = []; %This will be a string of formats used to read data rows
vects = 0;
all_data.time_vec = -1;
all_data.event_col = -1;
all_data.time_vec = -1;
time_format = 'unknown';
errorind = 'none';

%This section creates the information necessary to successfully read data
%from both ILIAD and C12 files. This is done one column header at a time.
for j=1:size(d_names,2)
    %First, ensure that the column header is a valid MATLAB variable name
    expression = ['isvarname(''',cell2mat(d_names(j)),''')'];
    isvar = eval(expression);
    if isvar ~= 1 %NOT a valid name...
        %Replace all characters that make a name not a variable name with
        %an underscore
        d_names{j} = regexprep(cell2mat(d_names(j)),'^\d|\W','_');
    end
    %handle known column names to extract times and events
    switch d_names{j}
        case {'IRIG_TIME'} %ILIAD IRIG time; this turns one column into four.
            ts_format=[ts_format '%f %f %f %f ']; %#ok<*AGROW>
            vects = vects + 1; save_names{vects} = [d_names{j} '_day'];
            vects = vects + 1; save_names{vects} = [d_names{j} '_hr'];
            vects = vects + 1; save_names{vects} = [d_names{j} '_min'];
            vects = vects + 1; save_names{vects} = [d_names{j} '_sec'];
            time_format = 'ILIAD';
            errorind = {'-1.#IND','1.#INF'}; %The ILIAD output for numerical errors
        case {'Delta_Irig','DELTA_IRIG'} %Identifies the running seconds column from ILIAD
            %output files.
            vects=vects+1;
            ts_format=[ts_format '%f '];
            save_names{vects} = d_names{j};
            all_data.time_vec = vects;
        case {'EVENT_COUNTER','ICU_EVNT_CNT','EVENT'} %Identifies the event column from ILIAD output
            vects=vects+1;
            ts_format=[ts_format '%f '];
            save_names{vects} = d_names{j};
            all_data.event_col = vects;
        otherwise
            vects=vects+1; %All other columns unless...
            %the name includes 'EVENT' then it is identified as the event
            %column
            if ~isempty(strfind(cell2mat(d_names(j)),'EVENT'))
                all_data.event_col = vects; end
            ts_format=[ts_format '%f '];
            save_names{vects} = d_names{j};
    end
end

%Some structure elements can be created directly.
all_data.vec_names = save_names;
%all_data.data = zeros(totrows,vects);
all_data.num_vecs = vects;
all_data.samples = totrows;
all_data.note = note;

%For the rest of the structure elements...

%Data must be read into the structure in pieces so that the typically large
%files do note choke the computer.
endrow=0; rowcount=0; dummy=0; count=0; %#ok<NASGU>

while rowcount<all_data.samples
    
    %Read in a slug of data. Multiple delimiters are necessary for C12
    %output but only the ',' delimiter is used in ILIAD output.
    C = textscan(fid_in, ts_format, split, 'delimiter', '[,:]',...
        'multipleDelimsAsOne', 0,... %Needed for C12 data
        'treatAsEmpty', errorind); %Depends on the data source

    startrow=endrow+1;
    endrow=endrow+length(C{1,1});

    %Append the numerical data to the data already saved.
    all_data.data(startrow:endrow,:)=cell2mat(C);

    %Let the user know the status of the read.
    count=count+1;
    if ishandle(stat); close(stat); end;
    stat = msgbox(['Creating Matlab structure from all data, '...
        num2str((count)/iterations*100) '% complete.'],'Progress...');
    
    [rowcount,dummy]=size(all_data.data); %#ok<NASGU>

end

%The data is all read now, so we can close the CSV file.
fclose(fid_in);

%C12 files need a time column and everything else needs some independent
%variable column for the data review utility.
if all_data.time_vec == -1
    switch time_format
        %No pre-identified running time column will cause the creation of a
        %vector of the row count
        case ('unknown')
            all_data.vec_names = ['count' all_data.vec_names];
            counts = [1:all_data.samples]';
            all_data.data = [counts all_data.data];
            [all_data.samples all_data.num_vecs] = size(all_data.data);
            all_data.time_vec = 1;
            %C12 files have enough data in the ASCII TIME column to create
            %a running time independent variable.
        case ('C12')
            dtime = all_data.data(:,dayvec)*24*60*60 +...
                all_data.data(:,hrvec)*60*60 +...
                all_data.data(:,minvec)*60 +...
                all_data.data(:,secvec);
            dtime = dtime - min(dtime);
            all_data.vec_names = ['DELTA_TIME' all_data.vec_names];
            all_data.data = [dtime all_data.data];
            [all_data.samples all_data.num_vecs] = size(all_data.data);
            all_data.time_vec = 1;
    end
    all_data.event_col = all_data.event_col + 1; %The time vector is added
    %as the first columns so the ID for the event column must be changed.
end

%Calculate the average sample rate. This data is not currently used by
%might be useful for future data processing in the data review GUI.
samp_rate = mean(all_data.data(2:end,all_data.time_vec)...
    - all_data.data(1:end-1,all_data.time_vec));
all_data.samp_rate_ave = samp_rate;

if ishandle(stat); close(stat); end %Close any open status windows

%The user is asked which vectors will serve as the default display vectors
%in the data utility tool.
[displayvecs,ok] = listdlg('PromptString',...
    'Select up to five parameters for the plots:',...
    'SelectionMode','multiple',...
    'ListString',all_data.vec_names,...
    'ListSize',[240 600],...
    'Name','Select Plot Parameters');

if ok==0 return; end %#ok<SEPEX>

displayvecs = [displayvecs 2 3 4 5 6]; %Add a buffer in case fewer than
%five vectors were selected
all_data.displayvecs = displayvecs(1:5); %Create the vector in all_data

%Create a 2xcolumns vector of YLims for later charting
padding = .025*(max(all_data.data)-min(all_data.data));
all_data.ylims = [min(all_data.data)-padding; max(all_data.data)+padding];
%k will be 0 if the YLims are the same...
k = 0 == (all_data.ylims(2,:)-all_data.ylims(1,:));
%Then it is used to make YLims for vectors with only one value
all_data.ylims(1,:) = all_data.ylims(1,:) - k;
all_data.ylims(2,:) = all_data.ylims(2,:) + k;

%The all_data structure is done, time to save it to the MAT file.
eval(['save ''' mat_data ''' all_data']);

%If there are unique event numbers and the user desires, create one
%additional structures for each event number
if all_data.event_col > 0 && events == 1
    %Find the event counter values
    event_data = eval(['all_data.data(:,' num2str(all_data.event_col) ');']);
    a = unique(event_data);
    event_counters = a(find(a>=0)); %#ok<FNDSB> %This is the vector of event counters
    %Create the event structures one at a time
    for i = 1:length(event_counters)
        counter = event_counters(i);
        stat = msgbox(['Creating structures for counter '...
            num2str(counter)], 'Progress...');
        indexes = find(counter==event_data); %Where the event counter data is
        if length(indexes) > 1
            event_str = ['EC_' num2str(counter, '%03g')];
            eval([event_str '=all_data;']);
            eval([event_str '.data = all_data.data(indexes,:);']);
            eval([event_str '.subset=''Event ' num2str(counter) ''';']);
            eval([event_str '.samples=length(indexes);']);
            eval([event_str...
                '.note=''Auto-Generated'';']);
            samp_rate = mean(eval([ event_str '.data(2:end,all_data.time_vec)'])...
                - eval([ event_str '.data(1:end-1,all_data.time_vec)']));
            eval([event_str '.samp_rate_ave = samp_rate;']);
            mins = eval(['min(' event_str '.data);']);
            maxs = eval(['max(' event_str '.data);']);
            padding = .025*(maxs-mins);
            eval([event_str '.ylims = [mins-padding; maxs+padding];']);
            eval(['k = 0 == (' event_str '.ylims(2,:)-' event_str '.ylims(1,:));']);
            eval([event_str '.ylims(1,:) = ' event_str '.ylims(1,:) - k;']);
            eval([event_str '.ylims(2,:) = ' event_str '.ylims(2,:) + k;']);
            eval(['save ''' mat_data ''' ' event_str ' -append']);
            if ishandle(stat); close(stat); end;
        else
            %Sometimes there is only one row for an event counter--these
            %event counters are skipped.
            stat = msgbox(['Event ' num2str(counter)...
                ' subset was not automatically generated; only one row.'],...
                'Progress...');
            pause(5); if ishandle(stat); close(stat); end;
        end
    end
end

stat = msgbox('Conversion complete!');
pause(5);
if ishandle(stat); close(stat); end
