function [data,varargout]=tpsread(varargin)

%TPSREAD single interface for commonly used read utilities at TPS
%
%   data=tpsread
%   data=tpsread(readfile)
%   data=tpsread(readfile,savetofile)
%   data=tpsread(readfile,savetofile,overwrite)
%   data=tpsread(readfile,true) % force save to default savetofile
%
%   readfile   - filename to be read, must end in .csv,.xls,.xfl, or .mat
%                Excel: can use a cell to send more data to xlsread
%                       {'myfile.xlsx','Sheet2'} instead of 'myfile.xlsx'
%   savetofile - .csv, .xls, and .xfl will be save to this .mat filename
%                -- if not provided the readfile will used, but with .mat 
%                -- set to [] to disable saving to a .mat file
%                -- this is ignored if the readfile is already a .mat file
%                -- a prompt is provided to override if it already exist
%   overwrite  - set to true to avoid prompt for overwriting existing .mat
%   data       - structure containing data, with fieldnames and .Info
%
%  Example:
%
%       data = tpsread('myfile.csv');  % myfile.mat will be created
%
%  written by: Maj Tim Jorris, TPS/CS, Jan 2010
%  v2.3     : Can handle "Time" as a 1st column header name
%  v2.2     : Changed internal data architecture to handle huge files
%             Fields were identified to only be 'single', a warning
%             will be displayed. To turn this annoyance off type
%  v2.1     : Added READASCX to read NASA ASC1 or ASC2 files
%  v1.1     : Replace bad time with NaN and produced warning (Dec 2008)
%             Number of rows is based on non-blank entries in 1st column
%  v1: 2008a: Fixed reading in csvfile
%             Modified to send more argument during Excel reading
%
% See also CSVREAD, XLSREAD

%% User must provide at least one output, the data variable
% if nargout == 0, error('You must provide an output data name'), end

%% There will always be an output
data=[]; % this will be returned if the user Cancels along the way

%% Perform all error checking for valid files and user options
[readfile,savetofile,savenewmat]=checkfiles(varargin{:});
if isnumeric(readfile), return, end % user pressed Cancel

%% readfile exist and ends with .csv, .xls, .xfl, or .mat
last4=readfile(end-3:end);

%% Remove old "hung" waitbars
wait_fig=findall(0,'Type','figure','Tag','TMWWaitbar');
if ~isempty(wait_fig), delete(wait_fig); end

%% Read the file based on the extension
switch last4
    case {'.asc','asc1','asc2','.mth','.gtd'}
        [data_num,names]=readascx(readfile); % numbers matrix, names
        for i=1:size(names,1)
            name=makevalid(deblank(names(i,:)));
            data.(name)=data_num(:,i);            
        end       
    case {'.csv'}
        data=csv2mat(readfile);
    case {'.xls','xlsx'}
        % Excel can handle other options. Provide the full user inputs if
        % provided
        if iscell(varargin{1})
            % Reset the first argument to the fixed readfile
            all_args=varargin{1};
            all_args{1}=readfile;
            data=xls2struct(all_args{:});
        else
            data=xls2struct(readfile);
        end              
    case {'.xfl'}
        [data,headerRecord,parameterRecord,eventData] =  ...
            readXFile(readfile);
        if nargout >=2
            varargout{1}=headerRecord;
            if nargout >=3
                varargout{2}=parameterRecord;
                if nargout >=4
                    varargout{3}=eventData;
                end
            end
        end
    case {'.mat'}
        data=loadmat(readfile);
    otherwise
        error(['Unknown extension ''',last4,''''])
end
%% Change Time Name
if ~isempty(data)
    if ~(isfield(data,'Time') || isfield(data,'TIME')) 
        if isfield(data,'TSECONDS') || ...
                isfield(data,'TIME')
            if isfield(data,'TSECONDS') 
                data.Time=data.TSECONDS;
                data=rmfield(data,'TSECONDS');
            else
                data.Time=data.TIME;
                data=rmfield(data,'TIME');
            end
            % Reorder to put 'Time' first
            fn=fieldnames(data);
            id=strmatch('Time',fn,'exact');
            fn(id)=[];
            fn=[{'Time'};fn];
            data=orderfields(data,fn);
        end
    end
end
%% Save to new .mat if appropriate
if savenewmat
    save(savetofile,'data')    
end

function [readfile,savetofile,savenewmat]=checkfiles(varargin)
% Painful Error Checking for files and overwrite options
nvargin=length(varargin);
if nvargin > 0, readfile=varargin{1}; end

%% Check for a valid readfile
if nvargin==0                        % Allow user to select a file
    readfile=getreadfile;  
    if isnumeric(readfile)
        savetofile=[]; savenewmat=false;
        return
    end % User pressed cancel
elseif ~ischar(readfile)            % Ensure the file provided is a string
    readfile=readfile{1};  % The rest will get sent to xlsread
% elseif exist(readfile,'file') ~= 2  % Verify the file exists
%     error(['The file provided below does not exist:',char(10), ...
%         '  ''',readfile,'''']);
elseif length(readfile) <= 4 || ( ...
        ~strcmpi(readfile(end-3:end),'.asc') && ...
        ~strcmpi(readfile(end-3:end),'asc1') && ...
        ~strcmpi(readfile(end-3:end),'asc2') && ...
        ~strcmpi(readfile(end-3:end),'.mth') && ...
        ~strcmpi(readfile(end-3:end),'.csv') && ...
        ~strcmpi(readfile(end-3:end),'.xls') &&...
        ~strcmpi(readfile(end-3:end),'.xfl') && ...
        ~strcmpi(readfile(end-3:end),'.mat') && ...
        ~strcmpi(readfile(end-3:end),'xlsx') )
    % it exist, but the extension is incorrect
    msg='The file provided must end in .csv, .xls, .xlsx, .xfl, or .mat:';
    error([msg,char(10), ...
        '  ''',readfile,'''']);
end

%% readfile exist and ends with .csv, .xls, .xfl, or .mat
last4=readfile(end-3:end);

%% Check for a valid savetofile
if nvargin < 2  % create a default savetofile
    if strcmp(last4(1),'.')
        savetofile=[readfile(1:end-4),'.mat'];   
    else
        savetofile=[readfile(1:end-5),'.mat'];
    end
else
    secondinput=varargin{2};
    savetofile=secondinput;
    if islogical(secondinput)
        if secondinput % overwrite is true
            if strcmp(last4(1),'.')
                savetofile=[readfile(1:end-4),'.mat'];
            else
                savetofile=[readfile(1:end-5),'.mat'];
            end
            if ~strcmpi(last4,'.mat')
                savenewmat=true;
            else
                savenewmat=false;
            end
        else 
            savetofile=[];
            savenewmat=false;
        end
    elseif ~isempty(savetofile) && ...
       (~isstr(savetofile) || ...
        length(savetofile) <= 4 || ...
        ~strcmpi(savetofile(end-3:end),'.mat'))
        error('savetofile must be a string ending in ''.mat''')
    end
end

%% Check for overwrite flag
if exist('savenewmat','var')==1 
    % do nothing, it's already been set to true
elseif nvargin==3
    savenewmat=varargin{3};
    if ~islogical(savenewmat)
        error('overwrite flag must be true or false')
    end
elseif nvargin >=2 && isempty(varargin{2})
    savenewmat=false;
else
    %% Perform the conversion if already .mat
    if strcmpi(last4,'.mat') 
        savenewmat=false;
    elseif exist(savetofile,'file')==2
        if ~exist('savenewmat','var') % ask the user
            opt1='Reconvert Only';
            opt2='Reconvert and Overwrite';
            opt3='Open .mat File Instead';
            response=questdlg(['Do you want to overwrite the following file?',char(10), ...
                savetofile],'Overwrite File?',opt1,opt2,opt3,opt3);
            if strcmp(response,opt1)
                savenewmat=false;
            elseif strcmp(response,opt2)
                savenewmat=true;
            elseif strcmp(response,opt3)
                readfile=savetofile;
                savenewmat=false;
                return
            else
                % User closed dialog or pressed Cancel
                readfile=0;
                savenewmat=false;
                return
            end
        elseif ~savenewmat
            readfile=savetofile; 
            return
        end
    else
        savenewmat=true;
    end
end

function readfile=getreadfile
%GETREADFILE The user has not provide one, so a gui browser will appear
[FileName,PathName]=uigetfile( {...
    '*.csv;*.xls;*.xlsx;*.xfl;*.mat','TPS Data Files (*.csv,*.xls,*.xlsx,*.xfl,*.mat)'; ...
    '*.*','All Files (*.*)'} );

if isnumeric(FileName) % User pressed Cancel
    readfile=FileName; % just so it has a value
    evalin('caller','return')
else
    readfile=fullfile(PathName,FileName);
end

function varargout=csv2mat(varargin)

%CSV2MAT Convert TPS csv files (C12 or ILIADs) to MATLAB structure 
%
%   csv2mat                       % dialog boxes will appear for inputs
%   csv2mat(csvfile)              % defines the csvfile to open
%   csv2mat(option1, value1, ...) % provide option and value pairs
%   data=csv2mat(...)             % capture the output instead of saving
%
%   Option          Value Pairs
%
%   'csvfile'       name of the input csv file
%   'matfile'       name of the output mat file
%                   (default is to save as csv with .mat extension)
%   'overwrite'     force an overwrite default matfile (default is false)
%   'note'          any note you'd like added to the structure
%   'split'         numeric, every nth point (default is 1)
% 
%  This is from of Bill Gray's TPS_data_norm GUI to allow batch processing.
%  Multiple files can be input as cell or selected, but the outcome will be
%   - .mat files the same name as the csv files (if no output is specified)
%   - a multi-dim structure array (if an output variable is specified)
%
%  modified by: Maj Tim Jorris, USAF TPS, Dec 2007
%
%  See also TEXTREAD, CSVREAD

% This has not been duplicates since it is merely a replication of data
%   'events'        set to 'true',1,'false', or 0 to separate events

% For the inputs to be converted into a structure they must be in pairs

if nargin==0, % do nothing
    use_gui=true;
elseif mod(nargin-1,2)~=0
    error('Options and values must be in pairs')
else
    options.csvfile=varargin{1};
end


% Create a structure based on the options, value pairs
if nargin == 0
    options=struct([]); % so something can be passed to setdefaults    
else
    options.csv=varargin{1};    % first input is csvfile
    for i=2:2:nargin
        options=setfield(options,lower(varargin{i}),varargin{i+1});
    end
end

% Ensure options have a value: nargout and overwrite used to see if needed
[options,abort]=setdefaults(options,nargout); 
if abort, return, end  % user didn't like matlab output names

% Call the csv converter
global CANCEL_CSV2MAT
for i=1:length(options.csvfile)  
    all_data=csv_to_structs(options.csvfile{i},options.matfile{i},...
        options.split,options.note,options.events);
    if CANCEL_CSV2MAT % i.e. returned early from reading csv file
        clear global CANCEL_CSV2MAT, try, delete(stat), catch, end % don't want bad handle to crash read
        if nargout > 0,
            out_data=all2out(all_data); % convert Gray's structure to user friendly structure        
            out_datas{i}=out_data;
            if i==1
                varargout{1}=out_data;
            else
                varargout{i}=out_datas;
            end
        end
        return
    else
        convert_irig=true;
        if nargout > 0 % user wants a structure array output
            out_data=all2out(all_data,convert_irig); % convert Gray's structure to user friendly structure        
            out_datas{i}=out_data;
            if i==1
                varargout{1}=out_data;
            else
                varargout{i}=out_datas;       
            end
        else           % user wants files saved to mat file
            % Overwrite was already determined in setdefault
            save(options.matfile{i},'all_data')
        end
    end        
end

% Done with reading, can remove global cancel variable
clear global CANCEL_CSV2MAT, try, delete(stat), catch, end

function [options,abort]=setdefaults(options,nout)
% This is only to ensure all options have value

abort=false; % only if user selects Cancel if matfiles already exist
% Simple defaults
if isempty(options)
    options=struct('split',1); % must use this format for empty struct
elseif ~isfield(options,'split')
    options.split=1;           % must use this to append a field
end
if ~isfield(options,'overwrite'),  options.overwrite=false; end   

if ~isfield(options,'events')
    options.events=0;
else    
    if isstr(options.events) && strcmpi(options.events,'true')
        options.events=1;
    else
        options.events=0;
    end
end
options.events = 0; % This is to force the non-use of events (for now)

if ~isfield(options,'csvfile')
    [filenames,pathname] = ...
        uigetfile('*.csv','Please select a CSV file or files', ...
            'MultiSelect','on');
    if isnumeric(filenames)
        abort=true;
        return  % User selected Cancel
    elseif iscell(filenames)    % User selected multiple files
    else filenames={filenames}; % create cell from single filenames
    end % filenames now exist as a cell array
    for i=1:length(filenames)   % Need full directory and filename
        filenames{i}=fullfile(pathname,filenames{i});
    end
    options.csvfile=filenames;
elseif isstr(options.csvfile)
    options.csvfile={options.csvfile};
end
if ~isfield(options,'note'), options.note='Created using tpsread'; end

if ~isfield(options,'matfile') && length(options.csvfile{:}) > 1
    % Need to create matfile from csvfile
    filenames=options.csvfile;
    matfiles=filenames; % this is just to pre-allocate the cell array
    for i=1:length(filenames)
        %[pathstr, name, ext, versn] = fileparts(filenames{i});
        [pathstr, name, ext] = fileparts(filenames{i});
        matfiles{i}=fullfile(pathstr,['tpsid_',name,'.mat']);
    end
    options.matfile=matfiles;
elseif ischar(options.matfile)
    options.matfile={options.matfile};      
end

% The default matfiles now exist, verify if overwrite will occur
if nout == 0 && ~options.overwrite
    foundit=zeros(size(options.matfile)); % just to get size correct
    for i=1:length(options.matfile)
        matfile=options.matfile{i};
        foundit(i)=exist(matfile,'file');
        % Add a path to ensure it's clear which on exist
        if foundit(i)
            temp=which(matfile); % this is the on "found";
            if ~isempty(temp)
                options.matfile{i}=matfile;
            end
        end
    end    
    % See if matfile exist, if so, ask the user what to do
    if any(foundit)
        response=questdlg({'The following .mat file(s) already exist:', ' ',...
            options.matfile{foundit>0},' '},...
            'File(s) Exist','Select New','Overwrite All','Cancel','Cancel');
        if isempty(response) || strcmp(response,'Cancel')
            abort=true;
            return
        elseif  strcmp(response,'Select New')
            for i=find(foundit>0)
                [filename,pathname]= ...
                    uiputfile('*.mat','Select an output .mat filename',...
                    options.matfile{i});
                if isnumeric(filename), CANCEL_CSV2MAT=true;
                    abort=true;                     
                    return
                else
                    options.matfile{i}=fullfile(pathname,filename);
                end
            end
        end
    end
end
%}

function all_data=csv_to_structs(csv_data,mat_data,split,note,events)
% slightly modified from Bill Gray's TPS_data_norm.  The textread with the 
% 'multipleDelimsAsOne' and 'treatAsEmpty' are enablers for this function.
% The ILIAD output inserts a -1.## into the csv file.  Almost all other csv
% readers fail since they do not have the 'treatAsEmpty','-1.#IND' handled.
% Bill also preallocates his matrix and reads in chunks to significantly
% speed up the csv reading.

%The BIG function...

% Debug only
% c=clock; all_data=struct('Time',c(end)); pause(1), return

% stat = msgbox(['Reading CSV file for conversion...'],'Progress');
global CANCEL_CSV2MAT, CANCEL_CSV2MAT=false;

stat=waitbar(0,['Reading ',csv_data,' ...'], ...
    'CreateCancelBtn','eval(''global CANCEL_CSV2MAT,CANCEL_CSV2MAT=true;'')',...
    'DefaultTextInterpret','none');


%Find the number of rows in the file
fid_in = fopen(csv_data);
if fid_in <= 0
    CANCEL_CSV2MAT=true;
    error(['File: ''',csv_data,''' not found'])
end
%firstcol = textscan(fid_in, '%s%*[^\n]','delimiter',',');
firstcol = textscan(fid_in,['%100s%*[^\n',char(236),']'],'delimiter',',');
if ~isempty(strfind(firstcol{1}{end},char(236)))
    firstcol{1} = firstcol{1}(1:end-1);
end

%{
try
    firstcol = textscan(fid_in, '%s%*[^\n]','delimiter',['[,',char(236),']']);
catch
    le=lasterror;
    if strcmp(le.identifier,'MATLAB:textscan:BufferOverflow')
        error('Run FIXCSV to fix this corrupted .csv file')
    else
        error(le)
    end
end
%}
fclose(fid_in);
totrows=size(firstcol{1,1},1)-1;
for i=totrows+1:-1:1    if isempty(firstcol{1}{i})
        totrows=totrows-1;
    end
end
        
clear firstcol;

%open the csv file for reading
fid_in = fopen(csv_data);
all_data.csvfile=csv_data;
%Read in the first row of data (assumed vector names)
C = textscan(fid_in, '%s',double(1), 'delimiter','\r'); %,...
% 'TreatAsEmpty',char(236),'EmptyValue',[]);
d_names = strread(C{1,1}{1,:},'%s','delimiter',',')'; %read vector names

if isnumeric(sscanf(d_names{1},'%f'))&&(isempty(sscanf(d_names{1},'%f'))==0) % No header row %Capt Olson added isempty part
   for i=1:length(d_names)  % All numbers {'.01','.02'}      
       d_names{i}=['col_',ExcelColumnLetter(i)];
   end
   fseek(fid_in,0,'bof'); % start over to read 1st line as data
%    fclose(fid_in)
%    fid_in = fopen(csv_data);
   totrows=totrows+1;
else
    % If one row is erroneously extended, then the csv file has blank
    % entries on all other rows.  We'll use the column headers to identify
    % the intended number or columns.
   id=true(size(d_names));
   for i=1:length(d_names)
       if isempty(d_names{i})
           id(i)=false;
       end
   end
   d_names=d_names(id); 
   % the '\r' during the names read can leave the file in the wrong place
   fseek(fid_in,0,'bof'); % start over to read 1st line as data
   junk=fgetl(fid_in); % "remove" first line from next read
end



%In this application, split is always 1, but in the future it might be
%advantageous to let the user choose how many rows per data read.
if split == 1
    split = round((totrows-1)/4);
    if split < 100
        split=100;
    else
        if split > 10000
            split = 10000;
        end
    end
end
iterations=round((totrows-1)/split+.5); %The number of data reads required

%Get to work... all_data is the structure that will contain the data. We
%start with the full data structure.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% v2: 2009a
%
% Total readjust of previous method. I use to bring all the data into a
% single matrix and then parce into separate fields within a structure.
% BUT, this unnecessarily creates a very large matrix. I could go straight
% to a structure, but I'd need to create unique field names now. Instead, I
% will contain each column of data in a continue, but separate cell. So,
% all_data.data will now be a cell array (vice a ginourmous matrix) and
% later converted into a structure.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

all_data.date = mat2str(clock);
all_data.subset = 'all_data';

%Initialize some variables
save_names = []; %This will be a vector of column names
ts_format = []; %This will be a string of formats used to read data rows
vects = 0;
all_data.time_vec = -1;
all_data.event_col = -1;
all_data.time_vec = -1;
time_format = 'unknown';
errorind = '-1.#IND00';

%This section creates the information necessary to successfully read data
%from both ILIAD and C12 files. This is done one column header at a time.
% errorind = {'-1.#IND','1.#INF'};
% errorind = {'-1.#IND'};
% errorind = {'-1.#IND','1.#INF','-1.#IND00'};
convert_irig=true; % either replace irig with seconds (true), or add more fields (false)
found_irig=false; % Already found an IRIG time, first will be default
dbls  = true;  % Formats will be true double, or false (single or required)
for j=1:size(d_names,2)
    %First, ensure that the column header is a valid MATLAB variable name
    expression = ['isvarname(''',cell2mat(d_names(j)),''')'];
    isvar = eval(expression);
    if isvar ~= 1 %NOT a valid name...
        %Replace all characters that make a name not a variable name with
        %an underscore
        d_names{j} = regexprep(cell2mat(d_names(j)),'^\d|\W','_');
    end
    if convert_irig
        
        switch d_names{j}
            case {'telem_time__ASCII_'} %C12 telemetry time; note that this
                %turns one column of data into four.
                ts_format=[ts_format '%s ']; vects = vects + 1;
                time_format = 'C12'; dbls(vects)=true;
                %if ~found_irig
                    all_data.time_vec = vects; 
                %end
                found_irig=true;
                save_names{vects} = d_names{j};
                errorind = '-1.#IND00'; %C12 output uses this for numerical errors
            case {'TIME__ASCII_'} %C12 time (used for running time DELTA_TIME);
                %note that this turns one column of data into four.
                ts_format=[ts_format '%s ']; vects = vects + 1;
                time_format = 'C12'; dbls(vects)=true;
              	if ~found_irig
                    all_data.time_vec = vects; 
                end
                found_irig=true;
                save_names{vects} = d_names{j};
                errorind = '-1.#IND00';
            case {'IRIG_TIME'} %ILIAD IRIG time (T38 and F16); this turns one
                %column into four.
                ts_format=[ts_format '%s ']; vects = vects + 1;
                % vects = vects + 1; save_names{vects} = [d_names{j} '_dsec'];
                time_format = 'ILIAD';
                errorind = {'-1.#IND','1.#INF'}; %The ILIAD output for numerical errors
                if ~found_irig
                    all_data.time_vec = vects; 
                end
                found_irig=true; dbls(vects)=true;
                save_names{vects} = d_names{j};
            case ('Delta_Irig') %Identifies the running seconds column from ILIAD
                %output files.                
                ts_format=[ts_format '%f ']; vects=vects+1;
                save_names{vects} = d_names{j};
                if ~found_irig
                    all_data.time_vec = vects;
                end, dbls(vects)=true;
                found_irig=true;
            case ('TIME')
                ts_format=[ts_format '%f ']; vects=vects+1;
                save_names{vects} = d_names{j};
                if ~found_irig
                    all_data.time_vec = vects;
                end, dbls(vects)=true;
                found_irig=true;
                time_format = 'TEST_OPS';     
            case ('EVENT_COUNTER') %Identifies the event column from ILIAD output                
                ts_format=[ts_format '%f ']; vects=vects+1;
                save_names{vects} = d_names{j};
                all_data.event_col = vects;
                dbls(vects)=false;
            case {'DAY','HOURS','MINUTES','SECONDS','MILLISECONDS', ...
                    'GPS_DAYS','GPS_HRS','GPS_MINS','GPS_SEC','GPS_MILL_SEC', ...
                    'IRIGREADER1-1','IRIGREADER1-2','IRIGREADER1-3',...
                    'IRIGREADER1-4','IRIGREADER1-5' ...
                    'IRIG_SYNC','IRIG_SYNC','LH1','LH2','STATUS'}
                vects=vects+1;  dbls(vects)=false;
                ts_format=[ts_format '%f '];
                save_names{vects} = d_names{j};
            otherwise
                if j==1
                    prior_to_check=ftell(fid_in);
                    one_row_data=fgetl(fid_in); % read a line
                    fseek(fid_in,prior_to_check,'bof'); % put it back
                    if length(one_row_data) >= 10 && any(findstr(one_row_data(1:10),':')) > 0
                        %note that this turns one column of data into four.
                        ts_format=[ts_format '%s ']; vects = vects + 1;
                        time_format = 'C12'; dbls(vects)=true;
                        if ~found_irig
                            all_data.time_vec = vects;
                        end
                        found_irig=true;
                        save_names{vects} = d_names{j};
                        errorind = '-1.#IND00';                %note that this turns one column of data into four.
                        continue
                    end
                end
                if length(d_names{j}) >= 3
                    switch d_names{j}(1:3)
                        case {'BSC','DSC'}
                            vects=vects+1;  dbls(vects)=false;
                            ts_format=[ts_format '%f '];
                            save_names{vects} = d_names{j};
                            continue
                    end
                end
                if length(d_names{j}) >= 5
                    switch d_names{j}(1:5)
                        case {'MFCPT1','TAIL_'}
                            vects=vects+1;  dbls(vects)=false;
                            ts_format=[ts_format '%f '];
                            save_names{vects} = d_names{j};
                            continue
                    end
                end
                
                vects=vects+1; %All other columns unless...
                %the name includes 'EVENT' then it is identified as the event
                %column
                dbls(vects)=true;
                if ~isempty(strfind(cell2mat(d_names(j)),'EVENT'))
                    all_data.event_col = vects; end
                ts_format=[ts_format '%f '];
                save_names{vects} = d_names{j};
        end
    else
        % handle known column names to extract times and events
        switch d_names{j}
            case {'telem_time__ASCII_'} %C12 telemetry time; note that this
                %turns one column of data into four.
                ts_format=[ts_format '%f %f %f %f '];
                vects = vects + 1; save_names{vects} = [d_names{j} '_day'];
                vects = vects + 1; save_names{vects} = [d_names{j} '_hr'];
                vects = vects + 1; save_names{vects} = [d_names{j} '_min'];
                vects = vects + 1; save_names{vects} = [d_names{j} '_sec'];
                time_format = 'C12';
                errorind = '-1.#IND00'; %C12 output uses this for numerical errors
            case {'TIME__ASCII_'} %C12 time (used for running time DELTA_TIME);
                %note that this turns one column of data into four.
                ts_format=[ts_format '%f %f %f %f '];
                vects = vects + 1; save_names{vects} = [d_names{j} '_day'];
                dayvec = vects;
                vects = vects + 1; save_names{vects} = [d_names{j} '_hr'];
                hrvec = vects;
                vects = vects + 1; save_names{vects} = [d_names{j} '_min'];
                minvec = vects;
                vects = vects + 1; save_names{vects} = [d_names{j} '_sec'];
                secvec = vects;
                time_format = 'C12';
                errorind = '-1.#IND00';
            case {'IRIG_TIME'} %ILIAD IRIG time (T38 and F16); this turns one
                %column into four.
                ts_format=[ts_format '%f %f %f %f '];
                vects = vects + 1; save_names{vects} = [d_names{j} '_day'];
                vects = vects + 1; save_names{vects} = [d_names{j} '_hr'];
                vects = vects + 1; save_names{vects} = [d_names{j} '_min'];
                vects = vects + 1; save_names{vects} = [d_names{j} '_sec'];
                % vects = vects + 1; save_names{vects} = [d_names{j} '_dsec'];
                time_format = 'ILIAD';
                errorind = {'-1.#IND','1.#INF'}; %The ILIAD output for numerical errors
            case ('TIME')
                vects=vects+1;
                ts_format=[ts_format '%f '];
                save_names{vects} = d_names{j};
                all_data.time_vec = vects;    
                time_format = 'TEST_OPS';
            case ('Delta_Irig') %Identifies the running seconds column from ILIAD
                %output files.
                vects=vects+1;
                ts_format=[ts_format '%f '];
                save_names{vects} = d_names{j};
                all_data.time_vec = vects;
            case ('EVENT_COUNTER') %Identifies the event column from ILIAD output
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
    if CANCEL_CSV2MAT, delete(stat), fclose(fid_in); return, end
end

%Some structure elements can be created directly.
all_data.vec_names = save_names;
all_data.data=cell(vects,1);  % v2: 2009a
try    
    for i=1:vects % yes a for loop, this avoids an OUT OF MEMORY matrix
        all_data.data{i} = zeros(totrows,1,'double');
    end
catch Too_Large_Error
    all_data=rmfield(all_data,'data');  % should free up memory
    for i=1:vects % yes a for loop, this avoids an OUT OF MEMORY matrix
        if dbls(i)
            double_fmt='single';
            all_data.data{i} = zeros(totrows,1,double_fmt);
        else
            non_double_fmt='int32'; 
            non_double_fmt='single'; % single takse same room, no multiplication issues
            %  all_data.data{i} = zeros(totrows,1,'single'); % 4 bytes
            all_data.data{i} = zeros(totrows,1,non_double_fmt); % 4 bytes
        end
    end
%     if nnz(~dbls) > 0
%         warning('tpsread:int32',['The following fields are limited to ''',non_double_fmt,''''])
%         saved_as_int32_cols=save_names(~dbls)
%     end
    warning('File too large: data is only saved as ''single'' precision')
end


all_data.num_vecs = vects;
all_data.samples = totrows;
all_data.note = note;

%For the rest of the structure elements...

%Data must be read into the structure in pieces so that the typically large
%files do note choke the computer.
endrow=0;
global PREVIOUS_FID_POS % debug only
%**************************************************************************
% 2008b Bug:
%   The &^*^%ing space at the end of the format command was causing an
%   error because there was no number followed by a space. This 'bug'
%   worked in 2007b but was causing an error in 2008b. Furthermore, the
%   'ReturnOnError' defaults to 1. A 1 implies to proceed as if nothing's
%   wrong if there is an error in the read. This makes it very difficult to
%   identify problems. I set it to 0 and put inside a try catch to make a
%   cleaner error and provide a message to trouble shoot. This was not an
%   intuitive fix, but it's done - Maj Tim Jorris, TPS/CS, Jan 2009
% OR!!! The fix was to ignore char(13) and/or char(10). Adding this to the
% delimiter list seemed to fix the problem. It works, I don't know which
% one, or both, fixed the problem.
ts_format=deblank(ts_format); % remove trailing blanks
%                             '%f ' is not really at the end, thus error
% ts_format=[ts_format,'\r']; % seems to work
ts_format=[ts_format,'%*[^\n]']; % This skips all columns greater than the intended number, good for bogus lines
    % 2008b fix, the '\r' at the end makes Matlab happy, AND I don't have
    % to put the '\r' in a delimiter (old method), thus I can set
    % MultipleDelimsAsOne to false to catch ILIAD blank columns   
%**************************************************************************
%***********
%

for i=1:iterations    
    %Read in a slug of data. Multiple delimiters are necessary for C12
    %output but only the ',' delimiter is used in ILIAD output.

%     [C, fid_pos] = textscan(fid_in, ts_format, split, 'delimiter', '[,: ]',...
%         'multipleDelimsAsOne', 1,... %Needed for C12 data
%         'treatAsEmpty', errorind); %Depends on the data source
    fid_pos=0; % global has a value, but not used for debugging
    % [C] = textscan(fid_in, ts_format, split, 'delimiter', '[,: ]',...    

    % [C,fid_pos] = textscan(fid_in, ts_format, double(split), 'delimiter', ['[,: ',char(236),']'],... 
    % ts_format=['%s ',ts_format(13:end)];    % debug, force new format
    % ts_format=['%s %s ',ts_format(25:end)]; % debug, force new format
    if i==iterations
        this_split=totrows-split*(iterations-1);
    else
        this_split=split;
    end
    method=1;

        % Con: Has trouble at beginning of file is there are a lot of
        % blank columns.
%         if isempty(C)
%     % method==2 inside the error
%         [C,fid_pos] = textscan(fid_in, ts_format, double(split), 'delimiter', ['[,: ',char(236),char(13),char(10),']'],...    
%         'MultipleDelimsAsOne', 1,... %Needed for C12 data
%         'ReturnOnError',0, ... % Avoids NOT detecting a bad file, i.e. ignoring the error and continuing is =1 behaviour
%         'TreatAsEmpty', errorind); %Depends on the data source
%         end

    1;  % just a placeholder to put a debug stop
    1;
    try

        [C,fid_pos] = textscan(fid_in, ts_format,double(this_split), 'delimiter', ['[,',char(236),']'],...    
        'CollectOutput', 0, ... % 2008b, either method works
        'MultipleDelimsAsOne', 0,... %Needed for C12 data
        'ReturnOnError',0, ... % Avoids NOT detecting a bad file, i.e. ignoring the error and continuing is =1 behaviour
        'TreatAsEmpty', errorind); %Depends on the data source

    catch Error_Message
       wait_fig=findall(0,'Type','figure','Tag','TMWWaitbar');
       delete(wait_fig)
       fclose(fid_in); 
       % Try to pinpoint the error with the info given. A common error
       % message will look like:
       %
       % Mismatch between file and format string.
       % Trouble reading floating point number from file (row 1, field 43) ==> \n
       %
       % I'd like to get the '1' and the '43'.  The '1' is in reference to
       % current block, but that could be after thousands of previously
       % read rows, so add that to startrow and account for the header row.
       % The field '43' is a column, but not intuit in Excel that that is
       % really column 'AQ'.      
       try % I don't want this 'helpful' error snooping to hide the real
           % error, thus 'try' it and if this errors, send back the
           % original error to the user.
           errmsg=Error_Message.message;
           find_row=findstr('row',errmsg);
           if ~isempty(find_row)
               find_comma=findstr(',',errmsg(find_row+1:end));
               if ~isempty(find_comma)
                   % +3 is for the 'o' and 'w' and plus one
                   % the -2 is one behind the comma
                   blockrow=sscanf(errmsg(find_row+3:find_row+find_comma-1),'%d');
                   if ~isempty(blockrow) % did it right have a number
                       badrow=endrow+blockrow+1; % 1 for header
                       find_field=findstr('field',errmsg);
                       if ~isempty(find_field)
                           find_paren=findstr(')',errmsg(find_field+1:end));
                           if ~isempty(find_paren)
                                badcol=sscanf(errmsg(find_field+5:find_field+find_paren-1),'%d');
                                if ~isempty(badcol)
                                    badcolabc=col2abc(badcol);
                                    % Finally our long desired error message
                                    line1=sprintf('Check csv Row %d Column %s for bad characters, extra columns, or spaces in last column.',badrow,badcolabc);
                                    My_Error.identifier=Error_Message.identifier;
                                    My_Error.message=['Error using ==> textscan',char(10),line1,char(10),errmsg];
                                    My_Error.stack=Error_Message.stack;
                                    Error_Message=My_Error;                                    
                                end
                           end
                       end                       
                   end
               end
           end                   
       catch New_Error
          % rethrow(Error_Message)
          % An error will void all progress thus far, treat like Cancel
          warning(Error_Message.identifier,Error_Message.message)
       end
    
       % find_row=findstr('row',
%        disp(' ')
%        disp(['A line caused a .csv read error, look for bad number (e.g. letters or #)', char(10), ...
%            'If a field is specified in the error below, look in that column (i.e. right before that many commas)'])
       % bad_read = C{1,1}(1) % if bad read this is previous success data
       % rethrow(Error_Message)
       warning(Error_Message.identifier,Error_Message.message)
       % If you are reading this you are probably in debug mode trying to
       % figure out why the csv won't read correctly.  A common problem is
       % an unrecognized string within the numerical data. Some candidates
       % are an bad number indicator, e.g. -1.#IND, thus you'd want to
       % specify errorind = {'-1.#IND'}; and rerun.  There may also be an
       % IRIG time 11:12:13.123 within the data. This will read correctly
       % since the colons are ignored, but the number of columns has
       % changed from one (between the commas) to three (found a number for
       % hours, one for minutes, and one for seconds). 
       return       
    end
    startrow=endrow+1;   
    if length(C{1,1}) <= 0
        break
    end
    if convert_irig % IRIG is read as string, must now be converted
        % But which ones, find them all
        for j=1:length(C)
            if iscellstr(C{j}) % I'm assuming it's IRIG, otherwise big issues
                [C{j},junk,errorid,errortxt]=get_time(C{j},startrow);
                if any(errorid) > 0
                    errortxt='Invalid time in row(s):';
                    for ij=1:length(errorid)
                        errortxt=[errortxt,char(10),'  ',num2str(startrow+errorid(ij))];
                    end
                    warning(errortxt)                    
                end
            end
        end
    end % Now everything is a number so cell2mat will work
    endrow=startrow+length(C{1,1})-1;
    if i==iterations && length(C{end}) < length(C{1})
        % Bug fix: Maj Tim Jorris
        % Some csv files have missing data at the end for some variables
        % If this occurs the cell2mat will error.  This will place NaN for
        % the missing variables.
        n_full=length(C{1});
        for j=1:length(C)   % each variable
            ctemp=NaN*ones(n_full,1);
            ctemp(1:length(C{j}))=C{j};  % The remaining NaN's will remain
            C{j}=ctemp;
        end            
    end
    %Append the numerical data to the data already saved.  
    % all_data.data(startrow:endrow,:)=cell2mat(C);
    % v2: 2009a all_data.data(startrow:endrow,:)=cell2mat(C);
    for icell=1:vects
        all_data.data{icell}(startrow:endrow)=C{icell};
    end
    % The cell2mat was causing an error, the PREVIOUS_FID_POS is used to
    % start reading just prior to the error to trouble shoot.  If an error
    % occurs, the PREVIOUS_FID_POS is not updated, hence previous.
    PREVIOUS_FID_POS=fid_pos;
    %Let the user know the status of the read.
%     if ishandle(stat); close(stat); end;
%     stat = msgbox(['Creating Matlab structure from all data, '...
%         num2str((i)/iterations*100) '% complete.'],'Progress...');    
    waitbar(i/iterations,stat,[num2str((i)/iterations*100) '% complete.'])
    if CANCEL_CSV2MAT, delete(stat), fclose(fid_in); return, end
end

%The data is all read now, so we can close the CSV file.
fclose(fid_in);
if CANCEL_CSV2MAT, delete(stat), return, end
%C12 files need a time column and everything else needs some independent
%variable column for the data review utility.
if all_data.time_vec == -1
    switch time_format
        %No pre-identified running time column will cause the creation of a
        %vector of the row count
        case ('unknown')
            all_data.vec_names = ['count' all_data.vec_names];
            counts = [1:all_data.samples]';
            % all_data.data = [counts all_data.data];
            all_data.data=[{counts};all_data.data];
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
time_vec=all_data.data{all_data.time_vec};
samp_rate = mean(time_vec(2:end)...
    - time_vec(1:end-1));
% samp_rate = mean(all_data.data(2:end,all_data.time_vec)...
%     - all_data.data(1:end-1,all_data.time_vec));
all_data.samp_rate_ave = samp_rate;

% if ishandle(stat); close(stat); end %Close any open status windows

%{
    % Remove to accommadate batch processing
%The user is asked which vectors will serve as the default display vectors
%in the data utility tool.
[displayvecs,ok] = listdlg('PromptString',...
    'Select up to five parameters for the plots:',...
    'SelectionMode','multiple',...
    'ListString',all_data.vec_names,...
    'ListSize',[240 600],...
    'Name','Select Plot Parameters');

if ok==0 return; end

displayvecs = [displayvecs 2 3 4 5 6]; %Add a buffer in case fewer than
%five vectors were selected
all_data.displayvecs = displayvecs(1:5); %Create the vector in all_data
%}
all_data.displayvecs=[1:5]; % Just a default to make TPS_data_utility work

%Create a 2xcolumns vector of YLims for later charting
% v2: 2009a
padding        =zeros(length(all_data.displayvecs),1);
all_data.ylims = zeros(2,length(all_data.displayvecs));
for i=all_data.displayvecs
    padding = .025*(max(all_data.data{i})-min(all_data.data{i}));
    all_data.ylims(:,i) = [min(all_data.data{i})-padding; max(all_data.data{i})+padding];
end
%k will be 0 if the YLims are the same...
k = 0 == (all_data.ylims(2,:)-all_data.ylims(1,:));
%Then it is used to make YLims for vectors with only one value
all_data.ylims(1,:) = all_data.ylims(1,:) - k;
all_data.ylims(2,:) = all_data.ylims(2,:) + k;

%The all_data structure is done, time to save it to the MAT file.
% -- Now going to be done in calling function
% eval(['save ''' mat_data ''' all_data']);

%If there are unique event numbers and the user desires, create one
%additional structures for each event number
if all_data.event_col > 0 & events == 1
    %Find the event counter values
    event_data = eval(['all_data.data(:,' num2str(all_data.event_col) ');']);
    a = unique(event_data);
    event_counters = a(find(a>=0)); %This is the vector of event counters
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

% stat = msgbox(['Conversion complete!']);
delete(stat)

if ishandle(stat); close(stat); end

function progf= waitbar_overload(varargin) % wrong name, ignored
%function progf= waitbar(varargin) % Use instead of MATLAB's
% USAGE: 
% waitbar(prog)                  % Update progress bar.
% waitbar(text)                  % New message text.
% waitbar(prog, text)            % Update progress bar and new message text.
% waitbar(text, arg1, arg2, ...) % New message text, works like sprintf(...).
% waitbar()                      % Deletes the waitbar window.
% 
% And for compatibility with the original Matlab waitbar:
% waitbar(prog, handle)
% handle= waitbar(prog, handle, text)
% handle= waitbar(prog, text, <property name/value list>)
% 
% A Matlab waitbar compatible replacement that is faster and more functional. 
% 
% ARGUMENTS:
% prog         (scalar, 0 <= prog <= 1) Progress value.
% text         (string) Sets/changes a message.
% handle       (numeric) Is ignored -- for compatibility with original waitbar.
% callback     (string) Is ignored -- for compatibility with original waitbar.
% <prop. ...>  (list) Sets figure properties to respective value. Special properties:
%              'DelayPeriod'   (default: 5.0)        Time until window is shown, [0, 60]. 
%              'LingerPeriod'  (default: 1.0)        Time until window is hidden, [0, 60]. 
%              'MinUpdateTime' (default: 0.5)        Minimum time between updates, [0, 10].
%              'Name'          (default: 'Progress') Progress bar window name.
%              'BarColor'      (default: 'b')        Progress bar colour. 
%              'CreateCancelBtn'                     For compatibility. Ignored. 
% 
% FUNCTIONALITY, like Matlab's original waitbar, but with some additions:
% 1.  It stays on top of other figures. 
% 2.  Minimal, really minimal, execution time overhead (some 10% of original waitbar's).
% 3.  Simpler to use, simpler calling and no figure handle to pass along.
% 4.  Only one waitbar window, so no old ones left around.
% 5.  Remaining time estimated and presented.
% 6.  Delay of 5 seconds before the waitbar is shown (no flashing at quick tasks).
% 7.  Window position is remembered during a Matlab session.
% 8.  Window is hidden 2 seconds after reaching prog == 1.0. If another task follows, 
%     there is time to continue progress reporting with no window flashing.
% 9.  If there is no window environment, textual feedback is used.
% 10. Information on process start and cpu time used. 
% 
% BUGS: If you find any bugs, please let me know: peder at axensten dot se.
% 
% EXAMPLE 1, simplest possible:
% nEnd= 100;
% for n= 1:nEnd
% pause(0.2); % Do stuff
% waitbar(n/nEnd);
% end
% 
% EXAMPLE 2, you can be more informative:
% nEnd= 100;
% waitbar(0, '(1 of 2) Preparing...', 'DelayPeriod', 0, 'LingerPeriod', 0, ...
%                 'MinUpdateTime', 0, 'Name', 'Other title...', 'BarColor', [0 1 0]);
% for n= 1:nEnd
% pause(0.1); % Prepare stuff
% waitbar(n/nEnd);
% end
% waitbar(0, '(2 of 2) Calculating...');
% for n= 1:nEnd
% pause(0.1); % Calculate stuff
% waitbar(n/nEnd);
% end
% 
% HISTORY:
% Version 1.0, 2006-06-14. 
% Version 1.1, 2006-06-15.
% - Fixed a timing bug and a debug info leak. 
% Version 1.2, 2006-07-16.
% - Added textual feedback, used when no graphical interface is available. 
% - Improved compatibility with original waitbar. 
% - Rewrote help text and comments a bit. 
% Version 1.3, 2006-07-27.
% - Mixed calls to plot-like functions and waitbar now works better.
% Version 1.4, 2006-09-09.
% - Made default values changeable via <prop/value> pairs. See DelayPeriod, LingerPeriod, 
%   MinUpdateTime, Name, and BarColor under "<prop. ...>", above. 
% - Mixing calls to plot-like functions and waitbar should now work. Many thanks to Yair Altman,  
%   who suggested fixes. 
% - Fixed a minor cosmetic bug (placement of bar). 
% Version 1.5, 2006-09-12.
% - Prefixes percentage to window title, e.g. '29% Progress'. 
% - Now the waitbar window is put on top of all figures after every call to it. 
% - Improved the output of the textual interface. 
% Version 1.6, 2006-09-23.
% - Now uses the GNU General Public License. 
% - Better compatibility with Matlab 6.5. 
% Version 1.7, 2006-09-26.
% - Added information on process start and cpu time used.
% - Improved timer handling. One rare warning removed. 
% - The percentage in the window title wasn't always updated. Fixed. Many thanks to Alberto 
%   Schiavone, who found this and other bugs.
% 
% COPYRIGHT:   2005, 2006 Peder Axensten. 
%              This file may be used according to the GNU General Public License.

% KEYWORDS:    wait bar, progress bar, process, time left, ETA
% INSPIRATORS: progressbar (6922), waitwaitbar (10795), Matlab waitbar.
% REQS:	       Matlab 6.5.1 (R13SP1). Might work (but is untested) on older versions.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	
	%%% Persistent variable's name must not conflict with workplace variable names.
	persistent win; 
	
	
	%%% Check if the minimum time between updates is up.
	thistime= clock;
	if(~isempty(win) && (abs(thistime(6)-win.last) <= win.mintime))
		if((nargin == 1) && isnumeric(varargin{1}) && (varargin{1} < 1))
			return;		% Calling waitbar(prog).
		elseif((nargin == 2) && isnumeric(varargin{1}) && (varargin{1} < 1) && isnumeric(varargin{2}))
			return;		% Calling waitbar(prog, handle).
		end
	end
	win.last=		thistime(6);
	if(~isfield(win, 'mintime'))
		win.mintime=	0.5; % [seconds]			% Default minimum update period.
	end
	
	
	%%% A call to waitbar() hides the progress window.	%%%%% No arguments: Hide window!
	if(nargin == 0)
		db=			dbstack;
		progf=		[];
		if(length(db) < 2),	db(2).name= '';	end			% Calling from the command win.
		try 
			if(isempty(win.start) || isempty(findstr(db(2).name, 'timercb')))
				% We want to reset this, in case we actually finished a process and then 
				% call waitbar without a message (previous one would show). If we close 
				% the waitbar window in midprocess, the message text should not be deleted.
				win.msg=			'';
				set(win.fighdl, 'Name', win.figtitle);	% Remove progress from window title.
				
				set(win.fighdl, 'Visible', 'off');
				win.start=			[];
				win.starttime=		'';
				win.vistimer=		handle_timer(win.vistimer, -1, '');
				win.lingertimer=	handle_timer(win.lingertimer, -1, '');
			end
			progf=	win.fighdl;
		catch
		end
		return;
	end
	
	
	%%% Check if we have a waitbar window already, create a new one if there is none.
	try	
		if(~win.text)
			ud=		get(win.fighdl, 'UserData');		% Does win.fighdl exist?
			if(isempty(ud) || (ud ~= 6808795978))
				win=	make_waitbarwin(win); 
			end
		end
	catch	% If we catch an error here, it's because the progress window was closed.
		win=	make_waitbarwin(win); 
	end
    
	
	%%% Are we starting a new process (making the window visible)?
	if(isempty(win.starttime))
		win.starttime=	sprintf('Started at %d:%02d:%02d, cpu time used: ', ...
									thistime(4), thistime(5), floor(thistime(6)));
		win.startcpu=	cputime;
	end
	
	
	%%% We have a waitbar and we want to do something with it. 
	prog= 			varargin{1};						% Progress value. 
	msgstr=			0;									% Default value (no message).
	if(isnumeric(prog) && (numel(prog) == 1))			%%%%% Update waitbar.
		
		
		%% Is there a message string in the call? If so, get it.
		%% Are there any property name/value pairs in the call? If so, get them.
		if((nargin == 3) && isnumeric(varargin{2}) && ischar(varargin{3}))
			msgstr=		varargin{3};		% waitbar(prog, handle, message).
		elseif((nargin == 2) && (isnumeric(varargin{2}) || isempty(varargin{2})))
			% Do nothing, but let through.	% waitbar(prog, handle).
		elseif((nargin >= 2) && ischar(varargin{2}) && (2*floor(nargin/2) == nargin))
			msgstr=		varargin{2};		% waitbar(prog, message, <optional name/value list>).
			if(~win.text && (nargin > 2) && ~strcmp(varargin{3}, 'CreateCancelBtn'))
				win=		set_properties(win, prog, varargin{3:end});
			end
		elseif(nargin >= 2)
			error('Wrong input argument(s), see ''help waitbar'' for correct use. [A]');
		end
		
		%% Create the eta string.
		if((prog < 0) || (prog > 1.001))
			error('The progress value must be in the interval [0,1].');
		elseif(prog >= 1)
			prog=		1;								% Maybe rounding errors.
			etastr=		'100% [0:00:00]';				% No ETA at end.
			
			% Wait to remove waitbar in case another (sub)task follows directly.
			win.lingertimer=	handle_timer(win.lingertimer, win.linger, [mfilename ';']);
			win.start=		[];							% Mark that we're done.
		elseif((prog == 0) || isempty(win.start))
			win.start=	clock;							% (Re)start timing.
			win.head=	true;							% We need to rewrite progress header.
			etastr=		'';								% No ETA at start.
		else
			s=		etime(clock,win.start);				% Time used so far.
			etastr=	sprintf('%3d%% [%s]', floor(100*prog), get_timestr(1 + s*(1/prog - 1)));
		end
		
		%% Update the progress information. 
		if(win.text)
			win=				text_progress(prog, etastr, msgstr, win);
		else
			set(win.etahdl,  'String', sprintf('%s\n', etastr));
			set(win.timehdl, 'String', [win.starttime get_timestr(cputime - win.startcpu)]);
			set(win.fighdl,  'Name',   [num2str(floor(100*prog)) '% ' win.figtitle]);
			set(win.proghdl, 'XData',  [0 prog prog 0]);
			win.winpos=			get(win.fighdl, 'Position');% Save progress window position. 
			if(ischar(msgstr)), set(win.msghdl, 'String', sprintf('%s\n', msgstr));	end
			drawnow;									% Force redraw.
		end
		if(ischar(msgstr)),		win.msg= msgstr;	end
	
	%%% We are calling with message argument(s) only. 
	elseif(ischar(prog))								%%%%% New message.
		progf=		waitbar(0, sprintf(varargin{:}));	% Default progress in this case is 0. 
		return;
	else 
		error('Wrong input argument(s), see ''help waitbar'' for correct use. [B]');
	end
	
	%%% Start delay timer. 
	if(strcmpi(get(win.fighdl, 'Visible'), 'off') && isempty(win.vistimer))
		win.vistimer=	handle_timer(win.vistimer, win.delay, ...
				['try set(' num2str(win.fighdl, 99) ', ''Visible'', ''on''); catch end']);
	end
	
	%%% Put the waitbar window on top of all others.
	children=		allchild(0);
	if(~win.text && (numel(children) > 1) && (children(1) ~= win.fighdl))
		uistack(win.fighdl, 'top');
	end
	
	%%% Return the figure handle (for campatibility reasons only). 
	progf=			win.fighdl;
return


function handle= handle_timer(handle, delay, timerfcn)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%	Handle timers.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	
	if(~isempty(handle))		% Remove timer. 
		stop(handle);
		delete(handle);
		handle=		[];
	end
	if(delay >= 0)				% Run timer. 
		try		% We might not have the required JAVA engine (textual interafce). 
			handle=	timer('TimerFcn', timerfcn, 'StartDelay', delay, 'Tag', 'waitbarTimer');
			start(handle);
		catch; end
	end
return


function timestr= get_timestr(s)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%	Return a time string, given seconds.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	
	h=			floor(s/3600);						% Hours.
	s=			s - h*3600;
	m=			floor(s/60);						% Minutes.
	s=			s - m*60;							% Seconds.
	timestr=	sprintf('%d:%02d:%02d', h, m, floor(s));
return


function data= set_properties(data, prog, varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%	Read property/value list and set values accordingly.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	
	if(mod(length(varargin), 2) ~= 0)
		error('Missing a value in property name/value list.');
	end
	for n= 1:2:length(varargin)
		switch(lower(varargin{n}))
			case 'createcancelbtn'	% Ignore...
			case 'delayperiod'
				data.delay=		min(60, max(0, varargin{n+1}));	% In [0, 60]. 
			case 'lingerperiod'
				data.linger=	min(60, max(0, varargin{n+1}));	% In [0, 60]. 
			case 'minupdatetime'
				data.mintime=	min(10, max(0, varargin{n+1}));	% In [0, 10]. 
			case 'name'
				data.figtitle=	varargin{n+1};
			case 'barcolor'
				data.barcolor=	varargin{n+1};
				set(data.proghdl, 'FaceColor', varargin{n+1});
			otherwise
				set(data.fighdl, varargin{n}, varargin{n+1});
		end
	end
return


function data= text_progress(prog, etastr, msgstr, data)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%	Write progress.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	
	if(ischar(msgstr))
		if(~strcmp(data.msg, msgstr))
			fprintf('%s\r***** %s\n', repmat(' ', 1, data.maxlen+17), msgstr);
		end
		data.header=	true;
	end
	
	if(prog > 0)
		if(data.header)
			width=		get(0,'CommandWindowSize');		% [width height] in chars.
			if    (width(1) >= 110),	divs=	10;
			elseif(width(1) >=  70),	divs=	 5;
			elseif(width(1) >=  60),	divs=	 4;
			elseif(width(1) >=  40),	divs=	 2;
			else						divs=	 1;
			end
			data.maxlen=	divs*10;
		
			data.theprog=		repmat('=', 1, data.maxlen);
			data.theback=		repmat('         :', 1, divs);
			data.theback(end)=	' ';
			data.header=		false;
		end
	
		fprintf('[%s%s] %s\r', data.theprog(1:floor(prog*data.maxlen)), ...
									data.theback(floor(prog*data.maxlen)+1:end), etastr);
		if(prog >= 1), fprintf('%s\r', repmat(' ', 1, data.maxlen+17));	end
	end
return


function data= make_waitbarwin(data)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%	Create default waitbar (gui or text?).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	
	if(~isfield(data, 'text'))
		data.text=			false;
		data.maxlen=		0;
		data.delay=			5.0; % [seconds]			% Default delay until window is visible.
		data.linger=		1.0; % [seconds]			% Default delay until window is hidden.
		data.figtitle=		'Progress';					% Default bar window title. 
		data.barcolor=		'b';						% Default bar color. 
		data.msg=			'';							% No message yet. 
		data.fighdl=		[];
		data.proghdl=		[];
		data.etahdl=		[];
		data.msghdl=		[];
		data.start=			[];							% Start present bar timing.
		data.starttime=		'';							% Time when progress window was shown.
		data.vistimer=		[];
		data.lingertimer=	[];
	end
	
	warning('off', 'MATLAB:m_warning_end_without_block');	% For Matlab 6.5. 
	
	% Call gui or text
	if(1 == prod(get(0,'ScreenSize')))				%%%%% Textual interface.
		data.text=			true;
		data.header=		true;
	else											%%%%% Graphival interface.
		% Get environment data.
		oldUnits=			get(0, 'Units');
		scrSz=				get(0, 'ScreenSize');
		set(0, 'Units', 'points');
		ppp=				72/get(0, 'ScreenPixelsPerInch');
		set(0, 'Units', oldUnits);
	
		% Calculate position of waitbar window and bar.
		barSze=				[400 16];	% [hor vert]
		barPlc=				[barSze(2) barSze(2)];
		barPos=				[barPlc barSze];
		winSze=				barSze + 2*barPlc + [0 30];
		if(~isfield(data, 'winpos'))
			data.winpos=		[(scrSz(3:4)-winSze)/2 winSze]*ppp;	% [left bottom width height]
		end
	
		% Delete all pre-existing waitbar graphical objects. 
		showhid=			get(0, 'showhid');
		set(0, 'showhid', 'on');
		try delete(findobj('Tag', 'Waitbar_Fig', 'UserData', 6808795978)); catch end
		set(0, 'showhid', showhid);
		
		% Delete timers. 
		data.vistimer=		handle_timer(data.vistimer, -1, '');
		data.lingertimer=	handle_timer(data.lingertimer, -1, '');
		
		% Create the interface objects. 
		data.fighdl=	figure(...
			'Units',				'points', ...
			'Position',				data.winpos, ...
			'NumberTitle',			'off', ...
			'Resize',				'off', ...
			'MenuBar',				'none', ...
			'Visible', 				'off', ...
			'Name', 				data.figtitle, ...
			'CloseRequestFcn',		'waitbar();', ...
			'HandleVisibility',		'off', ...
			'IntegerHandle',		'off', ...
			'Tag',					'Waitbar_Fig', ...
			'UserData', 			6808795978 );
		axhdl=			axes(...
			'Units',				'points', ...
			'Position',				barPos*ppp, ...
			'XLim',					[0 1], ...
			'YLim',					[0 1], ...
			'Box',					'on', ...
			'parent',				data.fighdl, ...
			'ytick',				[], ...
			'xtick',				[] );
		data.proghdl=	patch(...
			'XData',				[0 0 0 0], ...
			'YData',				[0 0 1 1], ...
			'FaceColor',			data.barcolor, ...
			'parent',				axhdl, ...
			'EraseMode',			'none' );
		data.etahdl=	text(1, 1, '', ...
			'parent',				axhdl, ...
			'Interpreter',			'none', ...
			'VerticalAlignment',	'bottom', ...
			'HorizontalAlignment',	'right' );
		data.timehdl=	text(1, -0.2, '', ...
			'parent',				axhdl, ...
			'Interpreter',			'none', ...
			'VerticalAlignment',	'top', ...
			'HorizontalAlignment',	'right', ...
			'FontSize',				9 );
		data.msghdl=	text(0, 1, data.msg, ...
			'parent',				axhdl, ...
			'Interpreter',			'none', ...
			'FontWeight',			'bold', ...
			'VerticalAlignment',	'bottom', ...
			'HorizontalAlignment',	'left' );
	end
return


function stc=all2out(all_data, convert_irig)
% Convert Bill Gray structure to user friendly structure
% function stc=all2stc(all_data)
%ALL2STC Convert the TPS data format, all_data, to structure
%
% stc=all2stc(all_data)
%
%  written by: Maj Tim Jorris, TPS/CS, Mar 2008
% 
% See also ALL2TSC

%% Add a missing columns, time in seconds from the first of the year

tnames={... % New T-38,  C-12     , % T-38 and F-16
    'DAY'         ,'TIME__ASCII__day' , 'IRIG_TIME_day', 'GPS_DAYS'    , 'GPS_DAYS'; ... % days
    'HOURS'       ,'TIME__ASCII__hr'  , 'IRIG_TIME_hr' , 'GPS_HRS'     , 'GPS_HRS' ; ... % hours
    'MINUTES'     ,'TIME__ASCII__min' , 'IRIG_TIME_min', 'GPS_MINS'    , 'GPS_MIN'; ... % minutes
    'SECONDS'     ,'TIME__ASCII__sec' , 'IRIG_TIME_sec', 'GPS_SEC'     , 'GPS_SEC' ; ... % seconds
    'MILLISECONDS','TIME__ASCII__sec' , 'IRIG_TIME_sec', 'GPS_MILL_SEC', 'GPS_MIL_SEC'};% milli-seconds    
%z turns it off so it can't be found

% tnames={... % New T-38,  C-12     , % T-38 and F-16
%     'TIME__ASCII__day' , 'IRIG_TIME_day', 'GPS_DAYS'; ... % days
%     'TIME__ASCII__hr'  , 'IRIG_TIME_hr' , 'GPS_HRS' ; ... % hours
%     'TIME__ASCII__min' , 'IRIG_TIME_min', 'GPS_MINS'; ... % minutes
%     'TIME__ASCII__sec' , 'IRIG_TIME_sec', 'GPS_SEC' ; ... % seconds
%     'TIME__ASCII__sec' , 'IRIG_TIME_sec', 'GPS_MILL_SEC'};% milli-seconds    

% Dummy milli's are zero'd out latter

%% Determine if it's C-12 or T-38 or Other above
j=0; % flag==0 means it was not found
for tj = 3:size(tnames,2)
    j=0;
    for ti=1:5
        if ~isempty(strmatch(tnames(ti,tj), all_data.vec_names))
            % found it
            j=1+j;
            if tj==1 || tj == 4 || tj == 5
                milli=1;
            else
                milli=0;
            end
            if j==5, break, end
        else
            break
        end
    end
    if j==5, break, end
end
% Turn off converting to IRIG, somethings wrong, go with IRIG_TIME in front
if j < 5
    j=0;
end

if j > 0 && (milli || all_data.time_vec==-1); % within cancel, time vec not created yet
    tdel=0;
    t0=   all_data.data{strmatch(tnames(1,tj),all_data.vec_names)}*86400 ...
    + all_data.data{strmatch(tnames(2,tj),all_data.vec_names)}*3600 ...
    + all_data.data{strmatch(tnames(3,tj),all_data.vec_names)}*60  ...
    + all_data.data{strmatch(tnames(4,tj),all_data.vec_names)};
    t0=double(t0) ...
        +milli/1000*double(all_data.data{strmatch(tnames(5,tj),all_data.vec_names)});    
else
    % tdel=all_data.data(:,all_data.time_vec);  % 0 to max seconds
    % v2: 1009a
    if all_data.time_vec<=0
        tdel=all_data.data{1};
    else
        tdel=all_data.data{all_data.time_vec};
    end
    if j == 0 
        t0=0.0;
    else
    t0=   all_data.data{strmatch(tnames(1,tj),all_data.vec_names)}(1)*86400 ...
        + all_data.data{strmatch(tnames(2,tj),all_data.vec_names)}(1)*3600 ...
        + all_data.data{strmatch(tnames(3,tj),all_data.vec_names)}(1)*60  ...
        + all_data.data{strmatch(tnames(4,tj),all_data.vec_names)}(1);
    t0=double(t0) ...
        +milli/1000*double(all_data.data{strmatch(tnames(5,tj),all_data.vec_names)}(1));
    end
end

% Create seconds after midnight, should be irig
tsec=t0+tdel;
stc=struct('TSECONDS',tsec);

for i=1:all_data.num_vecs
    % v2: 2009a
    fn=makevalid(all_data.vec_names{i});
    stc.(fn)=all_data.data{i};
end

%% Put the rest of the "information" in the UserData (under TimeInfo)
%
% I'm only going to "keep" the field that cannot be recreated.
% e.g. A recreatable field may be number of samples (length of data). 

remfd={'date','subset','csvfile','note','samp_rate_ave',...
       'displayvecs','ylims'}; % remaining fields
for i=1:length(remfd)
    if isfield(all_data, remfd{i})
        stc.Info.(remfd{i})=all_data.(remfd{i});
    end
end

%% Capture the prefix, e.g. 'C12_158_CTT__PHI'
for i=1:length(all_data.vec_names)
    [fn,prefix]=makevalid(all_data.vec_names{i});
    if ~isempty(prefix)
        stc.UserData.prefix=prefix;
        break
    end
end
function [fn,prefix]=makevalid(fn)

%MAKEVALID Correct the input fieldname in necessary to make it valid
%
%  fieldname=makevalid(fieldname)
%
% written by: Maj Tim "Boomer" Jorris, TPS Class 00B, Jan 2008

%Structure field names must begin with a letter, and are case-sensitive.
%The rest of the name may contain letters, numerals, and underscore
%characters. Use the namelengthmax function to determine the maximum length
%of a field name.
%
%letters=[65:90,97:122];  %---- ASCII number for a-z and A-Z
%numbers=[48:57];
%others=[95,32];          %---- underscore and space

% Truncate to no more than max allowed length using namelengthmax function
fn=fn(1:min(length(fn),namelengthmax));

%---- remove the 'C12_158_CTT__' in front of all variables
prefix=[];
if length(fn) > 13 && strcmpi(fn(1:3),'C12')
    prefix=fn(1:10);
    fn=fn(14:end);
end

% Verify the First Character is not a number
first=abs(fn(1));
if (first<65) | (first>90 & first<97) | (first > 122) % It's not a letter
    fn(1)='Z';
end

%---- define good characters. letters, numbers, and underscore
underscore=(fn==95); nums=(fn>=48  &  fn<=57 );
a_z=(fn>=65  &  fn<=90 ); A_Z=(fn>=97  &  fn<=122);

%---- substitute a underscore for all bad characters
bad=(~underscore & ~a_z & ~A_Z & ~nums);
if nnz(bad)>0
    fn(bad)=char('_'*nonzeros(bad));
end

function data=xls2struct(varargin)

%XLS2STRUCT Use XLSREAD to read data into structure
%
%          data=xls2struct(filename,...)
%
%  filename - Excel filename, a browser window is displayed of not provided 
%  ...      - whatever additional inputs xlsread can handle
%  data     - a structure with fieldnames from column headings
% 
% written by: Maj Tim Jorris, TPS/CS, July 2008
%
% See also XLSREAD

%% If user doesn't provide a filename, prompt for one
if nargin==0
    [f,p]=uigetfile({'*.xls','*.*'},'Please select a file');
    if isnumeric(f), return, end % User selected cancel
    filename=fullfile(p,f); 
    varargin{1}=filename;  % now it looks like it was user provided
end
% By now a filename has been provided
[num,ctxt]=xlsread(varargin{:});  % num is numeric matrix, txt is cell array
if size(ctxt,1)==0 ||  (size(num,2) > length(ctxt))
    if isempty(ctxt)
        for i=1:size(num,2)
            ctxt{i}=''; % will be taken care of later
        end
    else
        ctxt_old=ctxt;
        ctxt=cell(1,size(num,2));
        ctxt(1:size(ctxt_old,2))=ctxt_old;
    end
    % Now the size should be correct
elseif size(ctxt,1)==1    % all columns contain numeric data, no text holders in ctxt 
    % do nothing, time (first column) is already in numeric seconds
elseif size(ctxt,1)>1  % More than just a header row, text data contained within data area
    lastFirst=0;
    for i=1:size(ctxt,2) % look through each column
        if ~isempty(ctxt{2,i})
            % convert first row from seconds to irig
            t1_irig=ctxt(2:end,i); % first row is header
            t1_sec=get_time(t1_irig);
            if i==(lastFirst+1) % NaN's are not used as place holders in first column
                num=[num(:,1:lastFirst),t1_sec,num(:,lastFirst+1:end)]; lastFirst=i;
            elseif i==size(ctxt,2) % NaN's are not used as place holders in last column
                num=[num,t1_sec];
            else
                num(:,i)=t1_sec;  % Replace NaN place-holder with time in seconds
            end
        else
            break
        end
    end
end
% Time has now been added or not    
ncol_num=size(num,2); ncol_ctxt=size(ctxt,2);
if ncol_num ~= ncol_ctxt
    if ncol_num > ncol_ctxt
        num(:,ncol_ctxt+1:end)=[];
        line2='Extra columns of data were ignored.';    
    else
        ctxt(:,ncol_num+1)=[];
        line2='Extra column headings were ignored.';
    end
    warning(['The number of headers does not match the number of columns of data',char(10), ...
        line2])
    % Now there should be an equal number of headers and data
end
% Determine the size of the block of data, now includes time in seconds    
[nrow,ncol]=size(num);
cnames=ctxt(1,:);
% Convert the numeric data to cell array to convert to structure
cnum=num2cell(num,1)'; % each column becomes it's own cell
% Ensure all column names make valid field names
cnames=makevalid_cell(cnames);
% Rename 'Time' to 'TSECONDS' for consistency
for i=1:length(cnames)
    if strcmpi(cnames{i},'time')
        cnames{i}='TSECONDS';
        break
    end
end
% Finally convert to structure with field names
data=cell2struct(cnum,cnames);

function [cnames]=makevalid_cell(cnames)
%MAKEVALID Correct the input cell array to ensure they are valid fieldnames
%
%  fieldname=makevalid(cnames)
%
% written by: Maj Tim "Boomer" Jorris, TPS Class 00B, Jan 2008

%Structure field names must begin with a letter, and are case-sensitive.
%The rest of the name may contain letters, numerals, and underscore
%characters. Use the namelengthmax function to determine the maximum length
%of a field name.
%
%letters=[65:90,97:122];  %---- ASCII number for a-z and A-Z
%numbers=[48:57];
%others=[95,32];          %---- underscore and space


for i = 1:length(cnames)
    fn=cnames{i};  % Potential fieldname
    % Remove leading and trailing spaces
    if isempty(fn)
        % Maximum Columns is 16,384
        letters=ExcelColumnLetter(i);
        fn=['col_',letters];
    end
    fn=strtrim(fn);
    % Truncate to no more than max allowed length using namelengthmax function
    fn=fn(1:min(length(fn),namelengthmax));
    % Verify the First Character is not a number
    first=fn(1);
    if (first<65) || (first>90 && first<97) || (first > 122) % It's not a letter
           fn(1)='Z';
    end           
    %---- define good characters. letters, numbers, and underscore
    underscore=(fn==95); nums=(fn>=48  &  fn<=57 );
    a_z=(fn>=65  &  fn<=90 ); A_Z=(fn>=97  &  fn<=122);
    %---- substitute a underscore for all bad characters
    bad=(~underscore & ~a_z & ~A_Z & ~nums);
    if nnz(bad)>0
        fn(bad)=char('_'*nonzeros(bad));
    end
    % Re-insert corrected cell contents
    cnames{i}=fn;
end

function data=loadmat(readfile)
% Read in all variables from mat file
S=load(readfile);
fn=fieldnames(S);
found_data=0;
found_struct=0;
for i=1:length(fn)
    var=S.(fn{i});
    if isstruct(var) && (isfield(var,'Time') || isfield(var,'IRIG_TIME'))
        data=var;
        return
    elseif strcmp(fn{i},'data')
        found_data=i;
    elseif isstruct(var) 
        found_struct=i;
    elseif i==length(fn)
        % Assign whatever was found, outside this loop
    end
end
% Didn't find 'TSECONDS', 'TIME', or 'IRIG_TIME', what was found?
if found_data > 0
    data=S.(fn{found_data});
elseif found_struct > 0
    data=S.(fn{found_struct});
elseif length(fn) >= 1
    data=S.(fn{1});
else
    error(['No data found in:',char(10),...
        readfile])
end

function [tout,day,errorid,errortxt]=get_time(time,numsig,use_days)
% The guts are TPSTIME, the get_time name is for internal use only
% function tout=tpstime(time,numsig)
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

if isnumeric(time)
    % convert seconds to ddd:hh:mm:ss.sss
    day=floor(time/86400);                       % days
    hrs=floor((time-day*86400)/3600);            % hours
    min=floor((time-day*86400-hrs*3600)/60);     % minutes
    sec=time-day*86400-hrs*3600-min*60;          % seconds
    n=length(time);                              % length
    sday=reshape(sprintf('%03d:' ,day),4,n)';    % string days
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
    tfmt=['%',num2str(d2-d1+1),'d'];    errorid=0;
    [day,dcount, derrorid, derrortxt]=read_text(time(:,d1:d2),dfmt);  % days    
    % hrs=sscanf(time(:,h1:h2)',hfmt); % hours   
    [hrs,hcount, herrorid, herrortxt]=read_text(time(:,h1:h2),hfmt);  % hours  
    [min,mcount, merrorid, merrortxt]=read_text(time(:,m1:m2),mfmt);  % minutes
    [sec,scount, serrorid, serrortxt]=read_text(time(:,s1:end),sfmt); % seconds (good, handles ss.sss or ss.ssssss
    tout=day*86400+hrs*3600+min*60+sec;   % all together    
    if any(derrorid) > 0
        errorid=derrorid; errortxt=derrortxt;
    elseif any(herrorid) > 0
        errorid=herrorid; errortxt=herrortxt;
    elseif any(merrorid) > 0
        errorid=merrorid; errortxt=merrortxt;
    elseif any(serrorid) > 0
        errorid=serrorid; errortxt=serrortxt;
    else
        errorid=0; errortxt='';
    end
end

function [nums,count, errorid, errortxt]=read_text(txt, fmt)
% Bug fix. Time is suppose to look like ' 123 45:12:34:02.123' but some
% C-12 data would be all blanks except  '              362061' seconds
% The crude fix is to use a scanlist whenever the count does not match the
% number of items provided, i.e. a space was not read thus a null was put
% into that position.
len_txt=size(txt,1); errortxt='';
[nums,count]=sscanf(txt',fmt);
if count < len_txt && ~all(txt(end,:)==32)  % This scanlist takes twice as long so only use when necessary
    nums=NaN*zeros(len_txt,1); errorid=[];
    errortxt='Invalid times replaced with NaN in row(s):';
    for i=1:len_txt
        [temp,count]=sscanf(txt(i,:),fmt);
        if count==0
            nums(i)=NaN;
            errortxt=[errortxt,char(10),'  ',num2str(i)];
            errorid=[errorid;i];              
        else
            nums(i)=temp;
        end
    end
else
    errorid=0;
end
%     
%     num_col=size(txt,2); id=true(len_txt,1);
%     for i=1:size(txt,2)
%         id = id & ( txt(:,i)==32 | txt(:,i)==9);
%     end    
%     txt(id,3)='0';  % Now it will read in as something correct, i.e. 0
%     [nums,count]=sscanf(txt',fmt); % read again
%     if count < len_txt
%         error('Reading Error: Likely multiple blanks in place of day, hour, minute or seconds')
%     else
%         nums(id)=NaN; % NaN will tell user that spaces were there for day, hour, minute, etc
%     end
% end

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
max_try=size(str,2); this_try=0;
while sum(id) > 0 && this_try <= max_try
    this_try=this_try+1; % This means you've looped around with all spaces
    str(id,:)=[str(id,end),str(id,1:end-1)]; % move right blank to front
    id=str(:,end)==32;                       % a blank on the right
end

% function letters=col2letter(i)
% 
%         if i <= 26
%             letters=char(64+i);
%         elseif i <= (26*27)
%             remlet=floor((i-1)/26);
%             letters=char(64+remlet);
%             remlet=i-remlet*26;
%             letters=[letters,char(64+remlet)];
%         else
%             letters=sprintf('%05d',i); 
%         end
%         
function y=ExcelColumnLetter(col)
% Convert column numbers to Excel style letters (maximum ZZZZ)
%
% A simple function to convert an integer input to the equivalent string
% for numbering columns in Microsoft Excel worksheets
%
% Example: str=ExcelColumnLetter(n)
%
% where:
%           n is the column number (limited to between 1 and 475254)
%           str is the equivalent Excel string
%
% If n==1,   str=='A'
%    n==27,  str=='AA' 
%    n=999,  str=='ALK' etc
% 
% NB Your version of Excel may limit the number of columns in a worksheet
% e.g. up to 2003 only 256 were permitted.
%
% -------------------------------------------------------------------------
% Author: Malcolm Lidierth 10/08
% -------------------------------------------------------------------------

if col<1 || col>26+26^2+26^3+26^4 || rem(col,1)~=0
    error('Column number must be whole number between 1 and %d', 26+26^2+26^3+26^4);
elseif col>=1 && col<=26
    y=rem(col-1, 26);
elseif col>26 && col<=26+26^2
    x=col-26-1;
    y=[x/26 rem(x,26)];
elseif col>26+26^2 && col<=26+26^2+26^3
    x=col-26^2-26-1;
    y=[x/26^2 rem(x/26,26) rem(x,26)];
elseif col>26+26^2+26^3 && col<=26+26^2+26^3+26^4
    x=col-26^3-26^2-26-1;
    y=[x/26^3 rem(x/26^2,26) rem(x/26,26) rem(x,26)];
end
y=char(y+65);

return

function y=col2abc(col)
% Convert column numbers to Excel style letters (maximum ZZZZ)
%
% A simple function to convert an integer input to the equivalent string
% for numbering columns in Microsoft Excel worksheets
%
% Example: str=ExcelColumnLetter(n)
%
% where:
%           n is the column number (limited to between 1 and 475254)
%           str is the equivalent Excel string
%
% If n==1,   str=='A'
%    n==27,  str=='AA' 
%    n=999,  str=='ALK' etc
% 
% NB Your version of Excel may limit the number of columns in a worksheet
% e.g. up to 2003 only 256 were permitted.
%
% -------------------------------------------------------------------------
% Author: Malcolm Lidierth 10/08
% -------------------------------------------------------------------------

if col<1 || col>26+26^2+26^3+26^4 || rem(col,1)~=0
    error('Column number must be whole number between 1 and %d', 26+26^2+26^3+26^4);
elseif col>=1 && col<=26
    y=rem(col-1, 26);
elseif col>26 && col<=26+26^2
    x=col-26-1;
    y=[x/26 rem(x,26)];
elseif col>26+26^2 && col<=26+26^2+26^3
    x=col-26^2-26-1;
    y=[x/26^2 rem(x/26,26) rem(x,26)];
elseif col>26+26^2+26^3 && col<=26+26^2+26^3+26^4
    x=col-26^3-26^2-26-1;
    y=[x/26^3 rem(x/26^2,26) rem(x/26,26) rem(x,26)];
end
y=char(y+65);

return

function [data001,names,titles,dt,units]=readascx(filename,ilimit,minmax,nth_pt,out_ind)

%READASCx  Read GetData asc 1 OR asc2 format file into Matlab
%
%  [data001,names,titles,dt,units]=readascx(filename,ilimit,minmax,nth_pt,out_ind)
%  
%  (optional) implies it will be set to it's default if not provided.
%
%  filename - string filename including extention
%  ilimit   - (optional) allows the user to specify how much to do
%             -1 - read in the header only; names,titles,dt,units, and start_time
%                  start_time is the first time on the file, saved in data001
%              0 - read in header and all data (no limit) - FASTEST READ
%              1 - read header and limit time (time is always in the 1st column)
%              n - read header and limit the nth column, beware on scattered min max's%             
%             [default=0]  no limit read all points
%  minmax   - (optional) a two element vector specifying an upper and lower bound
%             if ilimit parameter is in ascending order (e.g. time)
%                  minmax(1)=min , minmax(2)=max
%             if ilimit parameter is in descending order (e.g. fuel)
%                  minmax(1)=max and minmax(2)=min 
%             [default=[]=null] read all points
%  nth_pt   - (optional) sample every nth point, must be integer > 1, 2 is every other point
%             this is really a first hack of recording at a lower sample rate.
%             [default=1] read all points
%  out_ind  - (optional) index of desired output parametes
%             e.g. out_ind=[1 4 5 26 125], will only record those 5 parameters, time is 1
%             [default=(all of the data file)]
%  names    - character matrix, one 13 long string name per row
%  data001  - columns: time, var1, var2, ...
%             rows   : each row is one time slice
%             var will be expressed within 13 spaces, including .,-,E-01
%             time equals seconds after midnight, 10 wide, 3 decimals
%  titles   - (optional) character matrix: each row max of 72 characters
%  dt       - (optional) nominal sample interval of the data frames. real 8
%  units    - (optional) same number as names, 16 character max
%
%  time minmax should be in seconds after midnight.
%
%  ilimit is best suited for time (ilimit=1).  READASCx stops reading as soon as
%  it finds the ilimit parameter outside minmax(2).  So if a wild point is
%  outside the minmax(2) bounds, file recording is over. This process, however, is
%  set up to avoid reading the rest of a long file if it no longer contains times
%  of interest. Use 'sample method' in the rundeck to capture all points within
%  the desired bounds.
        
%  the file does not need trailing spaces at the end of any records (i.e. lines).
%  format dictated by:
%  
%  'Flight Data Access System Programmer's Manual'
%  Richard E. Maine
%  7 Oct 97
%
%
%  See also  ASC22MAT, ASC22M WRITASC2, and OPENASCI

%-------------------------------------------------------------------------
%----- written by 1Lt Timothy R. Jorris, 29 Oct 97
%-------------------------------------------------------------------------


%-------------------------------------------------------------------------
%---- verify a value for every input argument, present or not
%-------------------------------------------------------------------------

%----- one record equates to one line on the ascii file

%------------------------------------------------------------
%----- Open file, and retrieve it's file id number
%------------------------------------------------------------

%---- verify that filename exist before continuing with readascx

fid = fopen(filename,'rb'); %---- open as read text

if fid < 0
   if ( isempty(filename) | all(isspace(filename)) | ~any(isletter(filename)) )
      filename='null';
   end
   fclose('all');
   msg=['READASCX: File ''', filename, ''' could not be found.', setstr(10), ...
        '          Please check the filename and/or directory.'];
   error(msg)
end


%------------------------------------------------------------------------
%----- There was some problems arising. The trailing spaces to
%----- reach 80 were left off in some formats, the solution is to use
%----- fgetl to retrieve the entire line, then parse the line accord-
%----- dingly.  Most will be the same except instead of using fscanf to
%----- read from the file, sscanf will be used to read from the temporary
%----- string (the one that has been read in as the entire line).
%-----
%----- [A,COUNT,ERRMSG,NEXTINDEX] = SSCANF(S,FORMAT,SIZE)
%-----
%----- Format notes
%-----   sscanf('    units 2  ','%s') will return 
%-----   'units2' of length 6
%-----   on the other hand
%-----   sscanf('    units 2  ','%c') will return
%-----   '    units 2  ' of length 13
%------------------------------------------------------------------------

%------------------------------------------------------------
%----- Format Header - must be first record
%------------------------------------------------------------

rec=fgetl(fid); %-----the entire record(i.e. whole line w/o CR or newline)
n=size(rec,2);  %-----length till end, may or may not be 80

while n < 20 %---- if we get to 20, other indexing and error handling works
       rec=[rec,' '];
       n=size(rec,2);
end

htype   =sscanf(rec(1:8) ,'%c'); %----- header type 
fformat =sscanf(rec(9:16),'%c'); %----- file format (may have a space don't use '%s')
fversion=sscanf(rec(17:n),'%c'); %----- format version 

%disp(['file header: ',htype,fformat,fversion]) %----- debug

%----- all strings are 8 long, clip trailing spaces and make lower case

htype=lower(htype(1:max(find(htype~=' '))));
fformat=lower(fformat(1:max(find(fformat~=' '))));
fversion=lower(fversion(1:max(find(fversion~=' '))));

%----- verify proper format

%--------------------------------------------------------------------
%----         Differences between ASC1 and ASC2
%----
%----                     ASC1                    ASC2
%---- Format Header -  'asc1' or 'asc 1'     'asc2' or 'asc 2'
%---- Title Header  -  same
%---- NChans Header -  same
%---- Names Header  -  5 x 16 long fields    6 x 13 long fields + 2 optional spaces
%---- Dt Header     -  same
%---- Units Header  -  same
%---- Data001 Header-  same
%---- Data records  -  4 x '%20.14g'         6 x '%13.7g'
%----
%---- Since Matlab reads whatever number is available, the format of
%---- of the Data records has no effect between the two formats.
%--------------------------------------------------------------------

if strcmp(htype,'format')
   if ( strcmp(fformat,'asc 1') | strcmp(fformat,'asc1') )
      namlen = 16;      %---- length of the names field
      nperl  = 5;       %---- number of names per line
      dform  = '%20f';   %---- flag for data001 read
   elseif ( strcmp(fformat,'asc 2') | strcmp(fformat,'asc2') )
      namlen = 13;      %---- length of the names field
      nperl  = 6;       %---- number of names per line
      dform  = '%13f';       %---- flag for data001 read
   else
      fformat
      fclose('all');
      error('READASCx: readascx can only read acs 1 (or asc1) or acs 2 (or asc2) files - see file header')
   end
else
   htype
   fclose('all');
   error('READASCx: first line should be format header starting with ''format''') 
end

%------------------------------------------------------------
%----- Title Header - optional (can be multiple records)
%------------------------------------------------------------

%----- capture position before starting htype test

pstart=ftell(fid);

%----- read the entire line, determine how long it is

rec=fgetl(fid);
n=size(rec,2);

%----- read first word on next line (it's in the temporary 'rec' string)

if n >= 8 %---- character region for 'title'
   htype=sscanf(rec(1:8),'%s'); %----- (no spaces allowed in name)
else
   htype=sscanf(rec(1:n),'%s');
end

htype=lower(htype);          %----- make case insensitive
titles=[];

%----- verify word matches 'title'
%----- read the rest of the 'title' record
%----- repeat for next records
%----- 'title' is a reserve matlab word so uses 'titles' as variable name

if strcmp(htype,'title')

   while strcmp(htype,'title')

      if n >= 9 %---- then a title does exist in the rest of the line
         tnext=sscanf(rec(9:n),'%c'); %---- all spaces included
      else  %---- for some reason the line has a 'title' header, but no text
         tnext='';
      end

      if size(titles,1)>=1 %---- 2nd-? rows, must str2mat them together
         titles=str2mat(titles,tnext);
      else %---- first row
         titles=tnext;
      end
      
      %---- get the next header, the 'while' loop may or may not continue    
      pstart=ftell(fid); %----- beginning position of next test
      rec=fgetl(fid);
      n=size(rec,2);
      if n >= 8 %---- character region for 'title'
         htype=sscanf(rec(1:8),'%s'); %----- (no spaces allowed in name)
      else
         htype=sscanf(rec(1:n),'%s');
      end     
   end % while
   %----- position before failed 'title' search
   fseek(fid,pstart,'bof');          
else
   %----- position before failed 'title' search
   fseek(fid,pstart,'bof');
end

%------------------------------------------------------------
%----- nChans Header - required
%------------------------------------------------------------

rec=fgetl(fid);
n=size(rec,2);

if n >= 8 %---- character region for 'nChans'
   htype=sscanf(rec(1:8),'%s');
else
   htype=sscanf(rec(1:n),'%s');
end

htype=lower(htype);   %---- make case insensitive

if strcmp(htype,'nchans') %---- must be case insensitive
   if n >= 9
      nchans=sscanf(rec(9:n),'%d'); %----- reads next number, the whole line
   else
      rec
      msg=['READASCx: The nChans number in the 9th position was not found'];
      fclose('all');
      error(msg)
   end
else
   htype
   fclose('all');
   error('wrong header type was found in place of ''nChans''')
end

%------------------------------------------------------------
%----- Names Header - required
%------------------------------------------------------------

%----- old method
%-----  %s16 will continue to read beyond 16 if no spaces are found
%-----  so if two 16 space names butt together, it would be read as one
%-----  to prevent this '%c',[1,16] reads 16 chars then cuts trailing spaces
%-----  asc2 is 13, asc1 is 16
%-----  also the 5 corresponds to 5*16 is 80 to make the line
%----- new method
%-----  read the entire line, then '%c' a 16 long string and the single name
%-----  with spaces will be the answer, use '%s' to grab with no spaces

%----- asc1 format is as follows, each entry takes up 16 spaces
%----- names n1 n2 n3 n4   % 1st line has 'names' and 4 name strings 
%----- n5    n6 n7 n7 n9   % 2nd-? lines have 5, until last name strings

rec=fgetl(fid);
n=size(rec,2);

if n >= namlen %---- region allocated for string 'names'
   htype=lower(sscanf(rec(1:namlen),'%s')); %---- make case insensative
else
   htype=lower(sscanf(rec(1:n),'%s')); %---- make case insensative
end

start=namlen+1;         %---- this is where the 1st name string starts
fin=(start+namlen)-1;   %---- 16 spaces minus 1 for indexing, end of name string

if strcmp(htype,'names')

   names='time'; %---- time is always first, so we will name it

   for i=1:nchans
      
       if (start <= n & fin <= n)
          ntemp=sscanf(rec(start:fin),'%c');
       elseif (start <= n)
          ntemp=sscanf(rec(start:n),'%c');
       else
          ntemp='no_name';
       end
       
       ntemp=ntemp(1:max(find(ntemp~=' ')));
       start=fin+1;
       fin=(start+namlen)-1; %---- 16 spaces minus 1 for indexing
       
       if any(ntemp==' ')
          disp(['READASCx: Warning. Spaces removed from ''',ntemp])
          ntemp=sscanf(ntemp,'%s'); %---- take spaces out so you have something         
       elseif isempty(ntemp)
          ntemp='no_name';
       end
       
       names=str2mat(names,ntemp);
       
       %---- ASC2
       %eval(['name',num2str(i),'=''',ntemp,''';'])
       %disp(['''',ntemp,''' ',int2str(wordread-1)]) %----- debug
       %----- the first line has 5 names, following have 6
       %----- thus 5-5=0, 0/6 has remander 0 for the first line
       %----- the next ends at the 11th name, 11-5=6, 6/6 has remainder 0
       %---- ASC1
       %eval(['name',num2str(i),'=''',ntemp,''';'])
       %disp(['''',ntemp,''' ',int2str(wordread-1)]) %----- debug
       %----- the first line has 4 names, following have 5
       %----- thus 4-4=0, 0/5 has remander 0 for the first line
       %----- the next ends at the 9th name, 9-4=5, 5/5 has remainder 0
              
       if (rem((i-(nperl-1)),nperl)==0 & i < nchans) %---- need to grab another line
           rec=fgetl(fid);
           n=size(rec,2);
           start=1;          %---- this is where the 1st name string starts
           fin=(start+namlen)-1; %---- 16 spaces minus 1 for indexing
       end

   end % for nchans

else
   htype
   fclose('all');
   error('READASCx:  wrong header type was found in place of ''names''')
end
 
%-------------------------------------------------------------------------
%----- Dt Header and/or Units Header - both optional, either order
%-----                                 (must be between Names and Data001)
%-------------------------------------------------------------------------

%-------------------------------------------------------------------------
%---- There are five possibilities:
%---- 1) neither dt nor units, go to the next test
%---- 2) dt only
%---- 3) units only
%---- 4) dt then units
%---- 5) units then dt
%---- if dt is 1st read it and check the next record
%---- if units is 1st, skip them, check for dt, if dt found read it
%---- Now dt is either read or not there
%---- if units were skipped, go back and read them
%---- 
%---- This is one way to avoid rewriting the units read code
%-------------------------------------------------------------------------

pstart=ftell(fid);
rec=fgetl(fid);
n=size(rec,2);

if n >= 8
   htype=lower(sscanf(rec(1:8),'%s'));
else
   htype=lower(sscanf(rec(1:n),'%s'));
end

bunits=0; %----- bolean units (t or f)
units=[];
bdt=0;    %----- bolean dt    (t or f)
dt=[];
pendu=pstart;
pendd=pstart;
if ( strcmp(htype,'dt') | strcmp(htype,'units') )

   %---- 1st test - check then reposition to next test point
   
   if strcmp(htype,'dt') %----- dt then maybe units
      bdt = 1;
      pdt = pstart;
   elseif strcmp(htype,'units') %----- units then maybe dt
      bunits=1;
      punits=pstart; %---- this will be the start of the 1st units line
      fseek(fid,punits,'bof'); %---- start at the beginning of units
      for i=1:ceil(nchans/4); %---- this is how many lines contain units
          fgetl(fid);
      end
   end
   
   %---- 2nd test
   
   pstart2=ftell(fid);
   rec=fgetl(fid);
   n=size(rec,2);
   if n >= 8
      htype2=lower(sscanf(rec(1:8),'%s')); %---- spaces will be eliminated
   else
      htype2=lower(sscanf(rec(1:n),'%s'));
   end

   if strcmp(htype2,'dt')
      bdt=1;
      pdt=pstart2;
   elseif strcmp(htype2,'units')
      bunits=1;
      punits=pstart2;
   end
   
   %---- read dt if it was found to exist
   
   if bdt
      fseek(fid,pdt,'bof');
      rec=fgetl(fid);
      n=size(rec,2);
      pendd=ftell(fid); %---- position end dt
      if n >= 9
         dt=sscanf(rec(9:n),'%e'); %----- reads next number, the whole line
      else
         dt=1;
         dt
         disp(['READASCx: ''dt'' header found, but no number in column 9-?'])
      end
   end
   
   %---- read units if it was found to exist
   
   if bunits
   
      fseek(fid, punits,'bof');
      %----- format 5*16, (8) 'units', (8) spaces, 4*(16) units
      %----- next line  , (8) spaces , (8) spaces, 4*(16) units
      rec=fgetl(fid);
      n=size(rec,2);
      start=17;
      fin=(start+16)-1;
      units='sec'; %---- the first defaults to time
      for i=1:nchans  
        
          if (start <= n & fin <= n)
             utemp=sscanf(rec(start:fin),'%c');
          elseif (start <= n)
             utemp=sscanf(rec(start:n),'%c');
          else
             utemp='?no?units?';
          end
          utemp=utemp(1:max(find(utemp~=' ')));
          if any(utemp==' ')
             disp(['READASCx: Warning. Units name ''',utemp,''' has a space in it'])
             utemp=sscanf(utemp,'%s'); %---- take spaces out
          end

          units=str2mat(units,utemp);
          
          
          if (rem(i,4)==0 & (i<nchans) ) %---- need to grab another line
              rec=fgetl(fid);
              n=size(rec,2);
              start=17;          %---- this is where the 1st unit string starts
              fin=(start+16)-1; %---- 13 spaces minus 1 for indexing, end of unit string
          else
              %---- go on to the next unit on in this record
              start=fin+1;
              fin=(start+16)-1;
          end % if rem              
      end % for i
      pendu=ftell(fid); %---- position end units
   end % if bunits
   
   %---- reposition at the end of the latter, units or dt
   
   if pendd >= pendu
      fseek(fid,pendd,'bof');
   else
      fseek(fid,pendu,'bof');
   end
   
else
   %----- position before failed 'dt and units' search
   fseek(fid,pstart,'bof');
end

%------------------------------------------------------------
%----                   UFTAS specific
%----          ilimit is not part of the asc1 format
%----
%---- Depending on the option, dictates if none, part, or all
%---- of data001 is read.  This is used by other functions to
%---- determine if this is a valid file, if it contains
%---- the search time, and then to process the entire data001.
%-------------------------------------------------------------


if ( nargin < 2 )
   ilimit=0;
   minmax=[];
elseif isempty(ilimit)
   ilimit=0;
   minmax=[];
else
   ilimit=fix(ilimit); %---- ensure ilimit is an integer
%elseif ( ioption~=1 & ioption~=2 & ioption~=3 )
%   disp('READASCx: ioption should be 1, 2, or 3; set to 3 as default')
%   ioption=3;
end

%if ilimit < 0 %---- header only (names,titles,dt, and units)
%   data001=[];
%   fclose(fid);
%   return
%end

%------------------------------------------------------------
%----                   minmax
%----
%---- if minmax is specified, restrict DATA001 to just the
%---- parameter search specified. 
%------------------------------------------------------------

lmin=[];
lmax=[];

if nargin < 3
   minmax=[];
%elseif (ilimit > 0 & ~isempty(minmax))
%---- now able to handle descending histories
%   if (minmax(1) > minmax(2))
%      temp=minmax(1);
%      minmax(1)=minmax(2);
%      minmax(2)=temp;
%      disp(['READASCx: minimum exceeded maximum, limits reversed.', setstr(10), ...
%            '          new min: ', sprintf('%f',minmax(1)), setstr(10), ...
%            '          new max: ', sprintf('%f',minmax(2))])
%   end
end

%------------------------------------------------------------
%----                   nth point
%----
%---- if nth_pt is greater than 1, than (nth_pt - 1) rows
%---- of numbers will be read from the file, but not recorded
%---- to data001.
%------------------------------------------------------------

if nargin < 4
   nth_pt = 1;
elseif isempty(nth_pt)
   nth_pt = 1;
end

recs=0; %---- number of valid records read in, valid being w/in time search

%------------------------------------------------------------
%----                   out_ind
%----
%---- feasibly there could be hundreds of parameters on one
%---- file, yet we may only be interested in 30.  If, through
%---- analyzing the input names, determine the index of the 30
%---- desired output, then that is all that will be recorded.
%---- If not specified, or invalid all the names are recorded.
%------------------------------------------------------------

if nargin < 5
   out_ind=1:nchans+1;     %---- an extra one for time
elseif isempty(out_ind)
   out_ind=1:nchans+1;       %---- an extra one for time
elseif ( length(out_ind) > nchans+1 )
   disp(['READASCx: requesting ',int2str(length(out_ind)),' and only ',int2str(nchans+1),' are on the file'])
   out_ind=1:nchans+1;       %---- an extra on for time
end

%------------------------------------------------------------
%----- Data001 Header - required
%------------------------------------------------------------

rec=fgetl(fid);
n=size(rec,2);
if n >= 8
   %----- should be the only thing in record (8)
   htype=lower(sscanf(rec(1:8),'%s'));
else
   htype=lower(sscanf(rec(1:n),'%s'));
end


if ( strcmp(htype,'data001'))

   first_spot=ftell(fid);
   data001=[];
   %----- let matlab do the fscanf using vectors
   m=nchans+1; %---- rows equals number of variable + time
   out_same=0;
   if length(out_ind)==m
      if all(out_ind==(1:m))
         out_same=1;
      end
   end
   if ( ilimit==0 & isempty(minmax) & nth_pt==1 & out_same)
      %---- this is by far the fastest way to load ALL of the data
      %---- read in m rows, transpose to get column time history 
      data001=fscanf(fid,dform,[m,inf])';
   else  %---- line by line
      
      %---- this is much slower, but allows for user options
 
      %----- read in the first row, which is read in as a column so transpose it
   
      datarow=[];
      %for i = 1:m
      %   onenum=fscanf(fid,dform,1);
      %   datarow=[datarow,onenum];
      %end
      datarow=fscanf(fid,dform,m)';
     
      if ( ~isempty(datarow) )
      
         if (ilimit < 0 )
            start_time=datarow(1,1);
            data001=start_time;
            fclose(fid);
            return
         elseif (ilimit > 0)
            lmin=datarow(1,ilimit);           
         end                  
      end

      if ( ~isempty(datarow) & ilimit==1 & namlen==16 )
         second_spot=ftell(fid);
         fseek(fid,0,'eof');
         end_spot=ftell(fid);
         fseek(fid,second_spot,'bof');
         %---- get the pointer to the first of the time limitation
         %---- this is an attempt to manage huge asc1 data files
         %---- asc2 can have an optional 2 space buffer which will void our
         %---- spacer counting.
         datarow=fscanf(fid,dform,m)';         
         if ~isempty(datarow)
            t_inc=datarow(1,1)-start_time;            %---- time increment
            hacks=floor((minmax(1)-start_time)/t_inc);  %---- number of time hacks            
            %---- new spot equals the first occurrance of time plus 20 spaces for
            %----    each parameter, plus a carrage return and line feed for every line
            %----    which is ceiling of the number of parameter divided by number per line=4            
            one_hack=20*m+2*ceil(m/4);            
            new_spot=first_spot+hacks*one_hack;
            if ( (new_spot < end_spot) & (hacks > 0) ) %---- don't go backwards to get there
               fseek(fid,new_spot,'bof');
               datarow=fscanf(fid,dform,m)';
               while datarow(1,1) > minmax(1)
                  %disp('backed up once')
                  %---- we overshot, probably a jump in time hacks
                  %---- rewind one hack to get to the last try + one more to back up one
                  fseek(fid,-2*one_hack,'cof');
                  datarow=fscanf(fid,dform,m)';
               end
            else
               fseek(fid,second_spot,'bof');
            end            
         else
            fseek(fid,second_spot,'bof');
         end
      end
   
      while ~isempty(datarow) %---- the last row will be empty
         saverec=0;
         if ilimit > 0
            %---- keep updating the new maximum on file
            lmax=datarow(1,ilimit);
         end
         
         %-----------------------------------
         %---- enforce min and max boundaries
         %-----------------------------------
         
         if (isempty(minmax)) %---- record all times, no limits, no sampling
            saverec=1;
         else
   
            if minmax(1) < minmax(2)     %---- ascending data assumed
         
               if ( minmax(1) <= datarow(ilimit) & datarow(ilimit) <= minmax(2) )
                  saverec=1;
               elseif ( datarow(ilimit) > minmax(2) ) %---- & ~isempty(data001) )
                  %---- collected all values in ascending order
                  saverec=0;
                  break
               end
               
            elseif minmax(1) > minmax(2) %---- descending data assumed
   
               if ( datarow(ilimit) <= minmax(1) & datarow(ilimit) >= minmax(2) )
                  saverec=1;
               elseif ( datarow(ilimit) < minmax(1) ) %---- & ~isempty(data001) )
                  %---- collected all values in descending order
                  saverec=0;
                  break
               end
            end
   
         end
   
   
         if saverec
            recs=recs+1; %---- number of valid records, recorded or not
         end
         
         %-----------------------------------
         %---- test for nth point sampling
         %-----------------------------------
         
         if ( saverec & rem(recs-1,nth_pt)==0 )
            saverec=1;
         else
            saverec=0;
         end

         %-----------------------------------
         %---- apply output index
         %-----------------------------------
         
         %---- record the data if it has met all criteria
         
         if ( saverec )
            %datanorm=[datarow(1,1)-start_time,datarow(1,2:m)];
            data001=[data001;datarow(out_ind)];
            %data001=[data001;datanorm];
         end
         
         datarow=fscanf(fid,dform,m)';
      end

      %---- Error Messages
      
      if (isempty(data001))
         if ilimit==0
            msg=[10,'READASCX: no data found after header ''data001'''];
         else           
            if (ilimit==1  & exist('get_time') )%---- time
               %---- puts time in hh:mm:ss.sss format; nice if available
               if ~isempty(minmax)
                  rstart=get_time(minmax(1));
                  r_stop=get_time(minmax(2));
               else
                  rstart=' ';
                  r_stop=' ';
               end
               fstart=get_time(lmin);
               f_stop=get_time(lmax);
            else
               if ~isempty(minmax)
                  rstart=num2str(minmax(1));
                  r_stop=num2str(minmax(2));
               else
                  rstart=' ';
                  r_stop=' ';
               end
               
               fstart=num2str(lmin);
               f_stop=num2str(lmax);
            end
              
            msg=[10, ...
               'READASCx: limited parameter ''',deblank(names(ilimit,:)),''' outside the scope of this file.',10, ...
               '          requested data from ',rstart,' to ',r_stop,10, ...
               '          parameter read from ',fstart,' to ',f_stop,10, ...
               '          no data recorded.'];            
            
         end
         disp(msg)
      end
         
   end
   
else
   htype
   fclose('all');
   error('READASCx: wrong header type was found in place of ''data001''')
end

%---- %**** -------------------------------------------------
%---  these are the original (and tested) way of reading the data
%***if strcmp(htype,'data001')
%***   %----- let matlab do all the work, no more formatted reading
%***   m=nchans+1; %---- rows equals number of variable + time
%***   %----- read in m rows, transpose to get column time history
%***   data001=fscanf(fid,'%f',[m,inf])';  
%***else
%***   htype
%***   fclose(fid);
%***   error('wrong header type was found in place of ''data001''')
%***end
%---- %**** -------------------------------------------------

%------------------------------------------------------------
%----- close the file - data001 is the last thing to be read
%------------------------------------------------------------

fclose(fid);


function [data,headerRecord,parameterRecord,eventData] = readXFile(filename,varargin)
% Reads data from the X-File file format
%
% SYNTAX:
% [data,headerRecord,parameterRecord] = readXFile(filename)
%   Retrieve all of the data
%
% [data,headerRecord,parameterRecord] = readXFile(...,inputTime)
%   Retrieve data for the given timeslice
%
% [data,headerRecord,parameterRecord,eventData] = readXFile(...,'EVENT_TIMES')
%   Retrieve data for the given events
%
% [data,headerRecord,parameterRecord] = readXFile(...,'TSECONDS')
%   Retrieve data for TSECONDS only
%
% INPUTS:
%   filename        Input file path
%   inputTime       Numeric array containing start/stop time for desired timeslice
%                       [DAYS,HH,MM,SS.SSS     Start Time
%                        DAYS,HH,MM,SS.SSS]    Stop Time
% OUTPUTS:
%   data            Output data structure
%   headerRecord    Header record structure
%   parameterRecord Parameter record structure
%   eventData       Numeric array containing values for start & stop times of
%                   events (from TSECONDS) in the format:
%                   [START_1, STOP_1
%                    START_2, STOP_2
%                      ...    ...
%                    START_n, STOP_n]
%
% EXAMPLES:
%   NONE
%
% DEPENDENCIES:
%   NONE
%     
% COMMENTS:
%   1) Ouptut parameter data types will be equal to X-File parameter data types
%   2) Parameters not to read can be set within the function
%   3) Time seek method can be set within the function
%
% REFERENCES:
%   NONE
%
% VERSION HISTORY:
%   06-08-06    John Bourgeois, AFFTC, U.S. Air Force
%   02-19-08    John Bourgeois, AFFTC, U.S. Air Force
%               *Added 'EVENT_TIMES' & 'TSECONDS' options

%****************************************************************************
eventData = [];

% Process inputs
inputTimeFlag = false;
eventTimesFlag = false;
tsecondsFlag = false;
for i = 1:length(varargin)
    if ischar(varargin{i})
        switch varargin{i}
            case 'EVENT_TIMES'
                eventTimesFlag = true;
            case 'TSECONDS'
                tsecondsFlag = true;
        end
    else
        inputTimeFlag = true;
    end
end

% Function flags
paramsSkip     = {'BLOCKNO','IRIGB'};  % Parameters to skip
timeSeekMethod = 'SMART_SEARCH';       % Method used to find position of input timeslice
                                       % 'DUMB_SEARCH'    Slow seek speed, medium accuracy
                                       % 'SMART_SEARCH'   Medium seek speed, high accuracy
                                       % 'GUESS'          Fast seek speed, low accuracy
   
add_irig=false; % call addirig instead
try
    % Open file
    fid = fopen(filename,'rb','ieee-be');

    % Read Header Record
    headerRecord.File_Type                  = fgetl(fid);
    headerRecord.File_Version_Number        = fgetl(fid);
    headerRecord.Date_Processed             = fgetl(fid);
    headerRecord.No_of_Parameters_Per_Block = str2num(fgetl(fid));
    headerRecord.Start_Byte_Of_Data         = str2num(fgetl(fid));
    headerRecord.Number_of_Bytes_Per_Block  = str2num(fgetl(fid));
    headerRecord.User_Comments              = struct('Name',{},'Value',{});
    while ~feof(fid)
        buf = fgetl(fid);
        if ~isempty(buf)
            k = strfind(buf,'=');
            headerRecord.User_Comments(end+1) = struct('Name',buf(1:k(1)-1),'Value',buf(k(1)+1:end));
        else
            break
        end
    end
    numParameters = headerRecord.No_of_Parameters_Per_Block;

    
%     for j = 1:1
%         parameterRecord(j).Parameter_Name          = 'IRIG_TIME';
%         parameterRecord(j).Parameter_Description   = 'Time in ddd:hh:mm:ss.ssssss';
%         parameterRecord(j).EU_low                  = 'text';
%         parameterRecord(j).EU_high                 = 'text';
%         parameterRecord(j).EU_units                = 'ddd:hh:mm:ss.sss';
%         parameterRecord(j).Parameter_Size_in_Bytes = 8;
%         parameterRecord(j).Start_Byte              = 0;
%         parameterRecord(j).Data_Type               = 'STRING';
%     end
    % Read Parameter Records
    for i = 1:numParameters
        buf = fgetl(fid);
        c = textscan(buf,'%s','delimiter','|');c = c{1};
        parameterRecord(i).Parameter_Name          = makevalid(c{1});
        parameterRecord(i).Parameter_Description   = c{2};
        parameterRecord(i).EU_low                  = c{3};
        parameterRecord(i).EU_high                 = c{4};
        parameterRecord(i).EU_units                = c{5};
        parameterRecord(i).Parameter_Size_in_Bytes = str2num(c{6});
        parameterRecord(i).Start_Byte              = str2num(c{7});
        parameterRecord(i).Data_Type               = c{8};
    end

    % Retrieve names of parameters contained in file
    parameterNamesAll = {parameterRecord.Parameter_Name};

    % Retrieve names of parmaeters to retrieve in file
    if tsecondsFlag
        parameterNamesGet = {'TSECONDS'};
    else
        parameterNamesGet = parameterNamesAll;
    end
    if eventTimesFlag
        if ~isempty(strmatch('EVENT_COUNTER',parameterNamesAll,'exact'))
            parameterNamesGet = [parameterNamesGet,'EVENT_COUNTER'];
        else
            eventTimesFlag = false;
        end
    end

    % Determine position of first parameter and number of blocks to retrieve
    if inputTimeFlag
        % Retrieve timeslice info
        inputTimeSlice = varargin{1};

        % Start/Stop time in seconds from first of year
        secsStart = inputTimeSlice(1,1)*(86400) + inputTimeSlice(1,2)*(3600) + inputTimeSlice(1,3)*60 + inputTimeSlice(1,4);
        secsStop = inputTimeSlice(2,1)*(86400) + inputTimeSlice(2,2)*(3600) + inputTimeSlice(2,3)*60 + inputTimeSlice(2,4);

        % Determine TSECONDS parameter info
        k = strmatch('TSECONDS',parameterNamesAll,'exact');
        skipBytes = headerRecord.Number_of_Bytes_Per_Block-parameterRecord(k).Parameter_Size_in_Bytes;
        if strcmpi(parameterRecord(k).Data_Type,'IEEE DP Float')
            strType = '*float64';
        else
            strType = '*float32';
        end

        switch timeSeekMethod
            case 'DUMB_SEARCH' % Perform a linear search from the first record
                % Move file position indicator to position of TSECONDS parameter in data block
                fseek(fid,headerRecord.Start_Byte_Of_Data+parameterRecord(k).Start_Byte,'bof');

                % Start index of data based on input timeslice info (point >= given start time)
                indStart = 1;
                while ~feof(fid)
                    secsCur = fread(fid,1,strType,skipBytes);
                    if secsCur >= secsStart
                        break
                    end
                    indStart = indStart+1;
                end

                % Stop index of data based on input timeslice info (point >= given stop time)
                indStop = indStart;
                while ~feof(fid)
                    secsCur = fread(fid,1,strType,skipBytes);
                    if secsCur >= secsStop
                        break
                    end
                    indStop = indStop+1;
                end

            case 'SMART_SEARCH' % Perform a search by using an intial guess and moving either backward or forward in time
                % Move file position indicator to position of TSECONDS parameter in data block
                fseek(fid,headerRecord.Start_Byte_Of_Data+parameterRecord(k).Start_Byte,'bof');

                % Determine delta time
                secsPoint1 = fread(fid,1,strType,skipBytes);
                secsPoint2 = fread(fid,1,strType,skipBytes);
                dt = secsPoint2-secsPoint1;

                % Start index of data based on input timeslice info (point <= given start time)
                indStart = floor((secsStart-secsPoint1)/dt);
                fseek(fid,(indStart-1)*headerRecord.Number_of_Bytes_Per_Block+headerRecord.Start_Byte_Of_Data+parameterRecord(k).Start_Byte,'bof');
                secs1 = fread(fid,1,strType,skipBytes);
                if secs1 < secsStart % Search forward (using two points, move forward)
                    while ~feof(fid)
                        secs2 = fread(fid,1,strType,skipBytes);
                        if secs1 == secsStart % Time is equal to left point
                            break
                        elseif secs2 == secsStart % Time is equal to right point
                            indStart = indStart+1;
                            break
                        elseif secsStart < secs2 % Time is between left and right point
                            break
                        else % Time is to the right of right point -> continue search
                            secs1 = secs2;
                            indStart = indStart+1;
                        end
                    end
                elseif  secs1 > secsStart % Search backward (using two points, move backward)
                    secs2 = secs1;
                    indStart = indStart-1;
                    while ~feof(fid)
                        fseek(fid,(indStart-1)*headerRecord.Number_of_Bytes_Per_Block+headerRecord.Start_Byte_Of_Data+parameterRecord(k).Start_Byte,'bof');
                        secs1 = fread(fid,1,strType);
                        if secs1 == secsStart % Time is equal to left point
                            break
                        elseif secs2 == secsStart % Time is equal to right point
                            indStart = indStart+1;
                            break
                        elseif secsStart < secs2 % Time is between left and right point
                            break
                        else % Time is to the left of left point -> continue search
                            secs2 = secs1;
                            indStart = indStart-1;
                        end
                    end
                end

                % Stop index of data based on input timeslice info (point >= given stop time)
                indStop = ceil((secsStop-secsPoint1)/dt);
                fseek(fid,(indStop-1)*headerRecord.Number_of_Bytes_Per_Block+headerRecord.Start_Byte_Of_Data+parameterRecord(k).Start_Byte,'bof');
                secs1 = fread(fid,1,strType,skipBytes);
                if secs1 < secsStop % Search forward (using two points, move forward)
                    while ~feof(fid)
                        secs2 = fread(fid,1,strType,skipBytes);
                        if secs1 == secsStop % Time is equal to left point
                            break
                        elseif secs2 == secsStop % Time is equal to right point
                            indStop = indStop+1;
                            break
                        elseif secsStop < secs2 % Time is between left and right point
                            indStop = indStop+1;
                            break
                        else % Time is to the right of right point -> continue search
                            secs1 = secs2;
                            indStop = indStop+1;
                        end
                    end
                elseif  secs1 > secsStop % Search backward (using two points, move backward)
                    secs2 = secs1;
                    indStop = indStop-1;
                    while ~feof(fid)
                        fseek(fid,(indStop-1)*headerRecord.Number_of_Bytes_Per_Block+headerRecord.Start_Byte_Of_Data+parameterRecord(k).Start_Byte,'bof');
                        secs1 = fread(fid,1,strType);
                        if secs1 == secsStop % Time is equal to left point
                            break
                        elseif secs2 == secsStop % Time is equal to right point
                            indStop = indStop+1;
                            break
                        elseif secsStop < secs2 % Time is between left and right point
                            indStop = indStop+1;
                            break
                        else % Time is to the left of left point -> continue search
                            secs2 = secs1;
                            indStop = indStop-1;
                        end
                    end
                end

            case 'GUESS' % Perform a guess based on the estimated delta time (retrieved from first two blocks)
                % Move file position indicator to position of TSECONDS parameter in data block
                fseek(fid,headerRecord.Start_Byte_Of_Data+parameterRecord(k).Start_Byte,'bof');

                % Determine delta time
                secs1 = fread(fid,1,strType,skipBytes);
                secs2 = fread(fid,1,strType,skipBytes);
                dt = secs2-secs1;

                % Start index of data based on input timeslice info (guess)
                indStart = floor((secsStart-secs1)/dt);

                % Stop index of data based on input timeslice info (guess)
                indStop = ceil((secsStop-secs1)/dt);

        end

        % Starting byte of first parameter within file
        startByte1 = (indStart-1)*headerRecord.Number_of_Bytes_Per_Block+headerRecord.Start_Byte_Of_Data;

        % Number of blocks to read
        numBlocks = indStop-indStart+1;
    else
        % Starting byte of first parameter within file
        startByte1 = headerRecord.Start_Byte_Of_Data;

        % Number of blocks to read
        numBlocks = inf;
    end

    % Read data
    for i = 1:length(parameterNamesGet)
        % Skip parameter if in "skip" list
        if ~isempty(strmatch(parameterNamesGet(i),paramsSkip,'exact'));
            continue
        end
        
        % Determine position of parameter in parameterRecord
        indParam = strmatch(parameterNamesGet(i),parameterNamesAll,'exact');


        % Starting byte of parameter within file
        startByte = startByte1 + parameterRecord(indParam).Start_Byte;

        % Move file position indicator to position of parameter in data block
        fseek(fid,startByte,'bof');

        % Read data
        skipBytes = headerRecord.Number_of_Bytes_Per_Block-parameterRecord(indParam).Parameter_Size_in_Bytes;
        switch parameterRecord(indParam).Data_Type
            case 'IRIGB'
                data.IRIGB_Days = fread(fid,numBlocks,'*uint32',skipBytes+4); % Read IRIG Days
                fseek(fid,startByte+4,'bof'); % Move to beginning of Milliseconds
                data.IRIGB_Milliseconds = fread(fid,numBlocks,'*uint32',skipBytes+4); % Read IRIG Milliseconds
            case 'IEEE SP Float'
                data.(parameterRecord(indParam).Parameter_Name) = fread(fid,numBlocks,'*float32',skipBytes);
            case 'IEEE DP Float'
                data.(parameterRecord(indParam).Parameter_Name) = fread(fid,numBlocks,'*float64',skipBytes);
            case 'Unsigned'
                data.(parameterRecord(indParam).Parameter_Name) = fread(fid,numBlocks,'*uint32',skipBytes);
            case '2''s Comp'
                data.(parameterRecord(indParam).Parameter_Name) = fread(fid,numBlocks,'*int32',skipBytes);
            otherwise
                error('Unsupported x-file parameter data type')
        end
    end

    
    if eventTimesFlag
        tseconds = data.TSECONDS;
        eventcounter = data.EVENT_COUNTER;
        numEvents = max(eventcounter);
        eventData = zeros(numEvents,2);
        for i = 1:numEvents
            times = tseconds(eventcounter == i);
            eventData(i,:) = [times(1),times(end)];
        end
    end

    % Add IRIG_TIME      
    if isfield(data,'TSECONDS') & add_irig
       names=fieldnames(data); len=length(names);
       tlen=length(data.TSECONDS);
       data.IRIG_TIME=cell(tlen,1);
       for i=1:tlen
            data.IRIG_TIME{i}=get_time(data.TSECONDS(i));      
       end
       names={'IRIG_TIME',names{:}}';       
       data=orderfields(data,[len+1;[1:len]']);       
    end
    % Close file
    fclose(fid);

catch
    fclose(fid);
    rethrow(lasterror);
end

% function fn=makevalid(fn)
% 
% %MAKEVALID Correct the input fieldname in necessary to make it valid
% %
% %  fieldname=makevalid(fieldname)
% %
% % written by: Maj Tim "Boomer" Jorris, TPS Class 00B, Jan 2008
% 
% %Structure field names must begin with a letter, and are case-sensitive.
% %The rest of the name may contain letters, numerals, and underscore
% %characters. Use the namelengthmax function to determine the maximum length
% %of a field name.
% %
% %letters=[65:90,97:122];  %---- ASCII number for a-z and A-Z
% %numbers=[48:57];
% %others=[95,32];          %---- underscore and space
% 
% % Truncate to no more than max allowed length using namelengthmax function
% fn=fn(1:min(length(fn),namelengthmax));
% 
% % Verify the First Character is not a number
% first=abs(fn(1));
% if (first<65) | (first>90 & first<97) | (first > 122) % It's not a letter
%     fn(1)='Z';
% end
% 
% %---- define good characters. letters, numbers, and underscore
% underscore=(fn==95); nums=(fn>=48  &  fn<=57 );
% a_z=(fn>=65  &  fn<=90 ); A_Z=(fn>=97  &  fn<=122);
% 
% %---- substitute a underscore for all bad characters
% bad=(~underscore & ~a_z & ~A_Z & ~nums);
% if nnz(bad)>0
%     fn(bad)=char('_'*nonzeros(bad));
% end

function [tsec,days]=gettime(time)%,digits,use_days)

%GET_TIME UFTAS converts dd:hh:mm:ss.s, dd hh:mm:ss.s, or hh:mm:ss.s to seconds after midnight
%
%       [tsec,day]=get_time(time,digits,use_days)
%
%  time     - text time in dd:hh:mm:ss.s or hh:mm:ss.s format (e.g. '213:21:53:04.1')
%             (if TIME is a number it must be in seconds after midnight)
%  digits   - (optional) percision of seconds as text ouput
%             [default=3, e.g. hh:mm:ss.sss]
%  use_days - (optional) output ddd:hh:mm:ss.sss
%             [default=false meaning hh may be greater than 24]
%
%  the default is from dd:hh:mm:ss.s to seconds. if time is a string the string
%  is converted to a number.  If time is a decimal (seconds from midnight)
%  then it is converted to 'hh:mm:ss.sss'. The dd is stripped and discarded if found.
%  convertions from seconds does not append the dd in front.
%  time can be a string matrix but spaces CANNOT be a delimiter between hh,mm,ss, or sss
%
%  day       - (optional) valid if time is dd:hh:mm:ss.s or dd hh:mm:ss.s, it is the dd
%
%  Note: If a vector is provided, then a check is performed to ensure a
%  change in days has not occurred.  This avoids 86398, 86399, 0, 1. The
%  convertion will contain seconds greater than 24 hours.
%
%  written by : Maj Tim Jorris, USAF TPS, Dec 2007               

% You can either have more than 24 hours our use days. The flag below will
% determine the behaviour. use_days=true implies ddd:hh:mm:ss.sss

day=fix(time/86400);
hour=fix((time-day*86400)/3600);
minute =fix( (time-hour*3600-day*86400)/60);
sec =time-day*86400-hour*3600-minute*60;
% best way to for ss.sss
tsec=sprintf('%03d:%02d:%02d:%02.6f',day,hour,minute,sec);





