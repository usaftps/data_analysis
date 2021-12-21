function varargout = TPS_data_utility(varargin)
%TPS_DATA_UTILITY M-file for TPS_data_utility.fig
%
%This tool will open a file (which must be named tpsid_*.mat) that consists
%of a single structure containing data either built in this GUI or using
%the m file iliad_to_matlab_struct. Tying "TPS_data_utility" at the >>
%prompt and returning will run the file.
%
%The data file can be opened using the initial dialog box. Once the data
%file is opened, if there is more than one subset to the data these subsets
%will be displayed so that one can be selected. The subset is then opened
%and the first five data vectors (not including the time vector) are
%plotted in their entirety.
%
%Individual points can be selected on the charts using a "datatip." To
%select a point, just put your mouse indicator inside a chart and a little
%"plus" symbol will appear. Click at a point on a graph and a box will pop
%up with the time and value at that point. Only one point can be selected
%at a time but multiple values can be marked using the "Add Line at
%Selection" button. Selcting data points is particularly useful when
%"zooming in" to see a particular time-slice.
%
%Buttons and text boxes (down the left side):
%-The name of the current tpsid_* structure/mat file is in the upper
%   left-hand corner.
%-"Choose New Data" allows the selection of a new tpsid_* mat file.
%-The name of the displayed subset. Pull down to choose a different one.
%-"Update Subset" updates the selected subset, cropping the subset to the
%   displayed time range and saving the selected dispay vectors as the default.
%-Five pull-down menus allowing parameter selection. The Y axis is
%   autoscaled.
%   --Each pull-down menu has an "IV" and "DV" button. Use
%   these to select independent and dependent values for later plotting
%   --The menus are not next to their respective axes to leave room for
%   later growth. But each axis is labeled in the upper left-hand corner
%   with the name of the plotted data.
%-"Create WS Vectors" allows you to choose from the entire list of vectors
%   then create vectors on your workspace of these data in the current time
%   range.
%-"Bode Analysis (DV/IV)" allows you to create a variety of bode plots
%   depicting the gain and phase relationships between two sets of data.
%   "IV" is the input variable and "DV" is the output variable--these are
%   selected using the pushbuttons above the selected parameters. Only the
%   data inside the current time frame are used.
%   --"Wrap Phase" forces the software to do just that.
%   --"Error Bands," when selected, depicts the gain and phase as an area
%   containing within the error bands defined by the number of standard
%   deviations you enter in the "SD:" box.
%   --"Margin Estimator" brings up an additional plot with Matlab's
%   built-in margin estimator results. This will only be meaningful with
%   very good data!
%-"Plot DV = fn(IV)" plots the selected variables against each other. For
%   instance, this makes it easy to see how a control surface position
%   changes as a function of the controller displacement.
%-"Add Line at Selection" is used to draw a vertical line through all five
%   graphs at the currently selected point. You cannot delete only one
%   line--to delete them all, click:
%-"Clear Selection Lines" to delete all vertical red lines created by the
%   "Add Line at Selection" box.
%-"TIP" and "MAG" give the user the option of selecting data via a
%   'datatip' (nearest data point to the cursor at the click) and
%   'magnifier' (the user draws a box and the data in that chart is
%   magnified. If "MAG" is used, the selected data is magnified and all
%   charts are set to the newly selected time range. After zooming, click
%   either "Set" buttons to set the chosen start and end times in the start
%   and end windows.
%-The start time and end time for the displayed data. These boxes can be
%   used to "zoom in" in time and also define the time range of any data to
%   be exported to Excel or saved as a new subset. The "Set" buttons below
%   each box allow the user to set the time to the time of the current data
%   point selection.
%"Reset Time" resets the time scale to the entire time scale of the current
%   subset.
%-The note for the current subset (entered by the user at creation) is
%   displayed along the bottom of the screen.
%
%Buttons and text boxes (Across the top):
%-"New Subset Name"
%   allows the user to name the new subset or Excel file. Do not add .xls to
%   create an xls file.
%-"Create New Subset" does just that. It DOES NOT open the new subset,
%   though; use the subset pull-down menu to do that.
%-"Select Params" allows the user to select those parameters that will be
%   saved to the Excel file. The time vector will always be
%   saved, whether it is selected or not. Once the parameters are selected,
%   they remain selected until changed by the user (the box is highlighted in
%   yellow and the name changed to signify that a subset of parameters will be
%   saved.)
%-"Create .xls File" does just that. The file will have a single worksheet
%   with headers and the parameters in the order stored in the structure. if
%   you choose a name that already exists in your current Matlab folder, it
%   will not overwrite the old file.
%-"Delete Subsets" presents a list of all subsets. Ctrl-click to select
%   multiple subsets. Confirmation required--they are permanently deleted!
%-"Quit" closes the GUI.
%
%Written by Bill Gray of the USAF Test Pilot School; this is a Version 1.0
%and any comments/suggestions are quite welcome and should be sent via
%email. This is also open-source so feel free to modify a copy. If your mods
%are an improvement, they can be incorporated into a new release with
%proper credit given.

% Last Modified by GUIDE v2.5 06-May-2013 10:55:55
%V1.0.1 Added the ability to create workspace vectors.
%V1.1 Added Bode analysis

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @TPS_data_utility_OpeningFcn, ...
    'gui_OutputFcn',  @TPS_data_utility_OutputFcn, ...
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


% --- Executes just before TPS_data_utility is made visible.
function TPS_data_utility_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   unrecognized PropertyName/PropertyValue pairs from the
%            command line (see VARARGIN)

% Choose default command line output for TPS_data_utility
handles.output = hObject;

[handles.FileName,handles.PathName] = uigetfile('tpsid_*','Select the M-file');
if handles.FileName == 0; return; end

%eval(['load ''' handles.file_under_eval '''']);

handles.file_under_eval = [handles.PathName handles.FileName];
eval(['s = who(''-file'', ''' handles.file_under_eval ''');'])
set(handles.file_under_evaluation,'String',handles.file_under_eval);

handles.sel_subset = 1;

set(handles.subset_under_eval, 'String', s, 'Value', handles.sel_subset);
handles.sel_subset = cell2mat(s(handles.sel_subset));
if ~isfield(handles,'datacursor')
    datacursormode on
    handles.dcm_obj = datacursormode(hObject);
    set(handles.dcm_obj, 'UpdateFcn', @tip_select)
    handles.datacursor = 'on';
end
handles.DV = 0;
handles.IV = 0;
set(handles.tip,'Value',1);
set(handles.mag,'Value',0);
handles.returned = 0;

% Update handles structure
guidata(hObject, handles);

load_sel_subset(hObject, eventdata, handles)

% UIWAIT makes TPS_data_utility wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = TPS_data_utility_OutputFcn(hObject, eventdata, handles)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes during object creation, after setting all properties.
function figure1_CreateFcn(hObject, eventdata, handles) %#ok<*INUSD>


% --- Executes during object deletion, before destroying properties.
function figure1_DeleteFcn(hObject, eventdata, handles)


% --- Executes on button press in quit.
function quit_Callback(hObject, eventdata, handles)

close(handles.figure1);



function start_time_Callback(hObject, eventdata, handles)

a = str2num(get(handles.start_time, 'String'));
if a >= handles.displayend
    set(handles.start_time, 'String', num2str(handles.displaystart));
    return
end
handles.displaystart = a;
handles.startind = find(handles.maindata.data(:,handles.maindata.time_vec)...
    >=handles.displaystart, 1, 'first');
handles.displaystart =...
    handles.maindata.data(handles.startind,handles.maindata.time_vec);
set(handles.start_time, 'String', num2str(handles.displaystart));

replot_all_axes(hObject, eventdata, handles)

guidata(hObject, handles);

function end_time_Callback(hObject, eventdata, handles)

a = str2num(get(handles.end_time, 'String'));
if a <= handles.displaystart
    set(handles.end_time, 'String', num2str(handles.displayend));
    return
end
handles.displayend = a;
handles.endind = find(handles.maindata.data(:,handles.maindata.time_vec)<=...
    handles.displayend, 1, 'last');
handles.displayend =...
    handles.maindata.data(handles.endind,handles.maindata.time_vec);
set(handles.end_time, 'String', num2str(handles.displayend));

replot_all_axes(hObject, eventdata, handles)

guidata(hObject, handles);

% --- Executes on selection change in popupmenu_axes1.
function popupmenu_axes1_Callback(hObject, eventdata, handles)


handles.maindata.displayvecs(1) = get(handles.popupmenu_axes1,'Value');
plot_axis(1, hObject, eventdata, handles)

% --- Executes on selection change in popupmenu_axes2.
function popupmenu_axes2_Callback(hObject, eventdata, handles)


handles.maindata.displayvecs(2) = get(handles.popupmenu_axes2,'Value');
plot_axis(2, hObject, eventdata, handles)

% --- Executes on selection change in popupmenu_axes3.
function popupmenu_axes3_Callback(hObject, eventdata, handles)


handles.maindata.displayvecs(3) = get(handles.popupmenu_axes3,'Value');
plot_axis(3, hObject, eventdata, handles)

% --- Executes on selection change in popupmenu_axes4.
function popupmenu_axes4_Callback(hObject, eventdata, handles)


handles.maindata.displayvecs(4) = get(handles.popupmenu_axes4,'Value');
plot_axis(4, hObject, eventdata, handles)

% --- Executes on selection change in popupmenu_axes5.
function popupmenu_axes5_Callback(hObject, eventdata, handles)


handles.maindata.displayvecs(5) = get(handles.popupmenu_axes5,'Value');
plot_axis(5, hObject, eventdata, handles)


% --- Executes on button press in reset_time.
function reset_time_Callback(hObject, eventdata, handles)

handles.displaystart = handles.datastart;
handles.startind =...
    find(handles.maindata.data(:,handles.maindata.time_vec)==handles.datastart);
handles.displayend = handles.dataend;
handles.endind =...
    find(handles.maindata.data(:,handles.maindata.time_vec)==handles.dataend);
set(handles.start_time, 'String', num2str(handles.displaystart));
set(handles.end_time, 'String', num2str(handles.displayend));

replot_all_axes(hObject, eventdata, handles)

guidata(hObject, handles);



function ds_name_edit_Callback(hObject, eventdata, handles)

handles.savename = get(handles.ds_name_edit, 'String');
handles.savename = textscan(handles.savename, '%s', 1, 'delimiter', '.');
handles.savename = cell2mat(handles.savename{1,1});
guidata(hObject, handles);


% --- Executes on button press in create_new_ds.
function create_new_ds_Callback(hObject, eventdata, handles)


disptime = get(handles.axes1,'XLim');
settime = [handles.displaystart handles.displayend];

if disptime ~= settime
    warndlg('Chart times do not match: click "Set" buttons first',...
        'Inconsistent time range...')
    return
end

if strcmp(handles.savename, 'New Subset Name')
    warndlg('Enter a new subset name first!','Missing subset name...')
    return
end

if ~isvarname(handles.savename)
    warndlg('The selected name is not a valid Matlab variable name.',...
        'Invalid Name...')
    return
end

if length(handles.savevecs) ~= handles.maindata.num_vecs
    button = questdlg('All parameters will be included. Continue?',...
        'Warning','Yes','No','Yes');
    if strcmp(button, 'No')
        return
    end
end

answer = inputdlg('Please enter a description (if desired):',...
    'Note Entry', 1, {'None'}, 'on');

if isempty(answer) return; end

stat = msgbox(['Creating and saving ''' handles.savename ''''],...
    'Standby...');

eval([handles.savename '.note=answer;'])
eval([handles.savename '.date=clock;']);
eval([handles.savename '.subset=''' handles.savename ''';']);
eval([handles.savename '.time_vec=handles.maindata.time_vec;']);
eval([handles.savename '.vec_names=handles.maindata.vec_names;']);
eval([handles.savename '.num_vecs=handles.maindata.num_vecs;']);
eval([handles.savename '.displayvecs=handles.maindata.displayvecs;']);
rows = [num2str(handles.startind) ':' num2str(handles.endind)];
columns  = ':';
eval([handles.savename '.data=handles.maindata.data(' rows ',' columns ');']);
totrows = eval(['size(' handles.savename '.data,1);']);
eval([handles.savename '.samples=' num2str(totrows) ';']);
high = eval([handles.savename '.data(2:end,' num2str(handles.maindata.time_vec) ');']);
low = eval([handles.savename '.data(1:end-1,' num2str(handles.maindata.time_vec) ');']);
eval([handles.savename '.samp_rate_ave=' num2str(mean(high-low)) ';']);

eval(['save ''' handles.file_under_eval ''' ' handles.savename ' -append']);

set(handles.ds_name_edit,'String','New Subset Name');

% Update handles structure
guidata(hObject, handles);

eval(['s = who(''-file'', ''' handles.file_under_eval ''');'])
handles.sel_subset = find(strcmp(handles.sel_subset,s)==1);
set(handles.subset_under_eval, 'String', s, 'Value', handles.sel_subset);
handles.sel_subset = s(handles.sel_subset);

if ishandle(stat); close(stat); end;

% --- Executes on button press in del_subset.
function del_subset_Callback(hObject, eventdata, handles)

eval(['s = who(''-file'', ''' handles.file_under_eval ''');'])
[del_subsets,ok] = listdlg('PromptString','Select subsets for deletion:',...
    'SelectionMode','multiple',...
    'ListString',s,...
    'Name','Delete Subsets');

if ok==0 return; end

del_strucs = s(del_subsets);

[del_subsets,ok] = listdlg('PromptString',...
    'Confirm the following subsets for deletion:',...
    'SelectionMode','multiple',...
    'ListString',del_strucs,...
    'Name','Confirm Deletion');

if ok==0 return; end

del_strucs = del_strucs(del_subsets);

save_strucs = [];
for i=1:length(s)
    delete_it = 0;
    for j=1:length(del_strucs)
        if strcmp(s(i),del_strucs(j))
            delete_it = 1;
        end
    end
    if delete_it == 0;
        save_strucs = [save_strucs ' ' cell2mat(s(i))];
    end
end

eval(['load ''' handles.file_under_eval '''']);
eval(['save ''' handles.file_under_eval ''' ' save_strucs]);

eval(['s = who(''-file'', ''' handles.file_under_eval ''');'])

if length(s) > 1
    [handles.sel_subset,ok] = listdlg('PromptString','Select a subset:',...
        'SelectionMode','single',...
        'ListString',s,...
        'Name','Select Subset');
    if ok==0 return; end
else
    handles.sel_subset = 1;
end

set(handles.subset_under_eval, 'String', s, 'Value', handles.sel_subset);
handles.sel_subset = cell2mat(s(handles.sel_subset));

guidata(hObject, handles);

load_sel_subset(hObject, eventdata, handles)


% --- Executes on button press in create_xls.
function create_xls_Callback(hObject, eventdata, handles)


disptime = get(handles.axes1,'XLim');
settime = [handles.displaystart handles.displayend];

if disptime ~= settime
    warndlg('Chart times do not match: click "Set" buttons first',...
        'Inconsistent time range...')
    return
end

if strcmp(handles.savename, 'New Subset Name')
    warndlg('Enter a subset name first!','Missing subset name...')
    return
end

result = []; badchar = {'\' '/' ':' '*' '?' '"' '<' '>' '|' '.' ''''};
for i=1:length(badchar);
    result = [result strfind(handles.savename, badchar{i})];
end

if ~isempty(result)
    warndlg(['Filename is not valid, please choose a name that '...
        'satisfies Windows filename requirements.'])
    return
end

decimate = ceil((handles.endind-handles.startind)/32000);
if decimate > 1
    message = ['Excel will not graph more than 32000 rows. Your selected ',...
        'data has ' num2str(handles.endind-handles.startind) ' rows so ',...
        'the rows will be decimated by a factor of ' num2str(decimate) ...
        ', resulting in ' num2str(ceil((handles.endind-handles.startind)/decimate)) ...
        ' total rows. Please standby while the file is created.'];
else
    message = 'Please standby while the file is created...';
end
h = msgbox(message);

xlswrite(handles.savename, handles.maindata.vec_names(handles.savevecs))
xlswrite(handles.savename,...
    handles.maindata.data(handles.startind:decimate:handles.endind,handles.savevecs),...
    'Sheet1', 'A2')

if ishandle(h); close(h); end;


% --- Executes on button press in choose_data.
function choose_data_Callback(hObject, eventdata, handles)

s = handles.maindata.vec_names;
[handles.savevecs,ok] = listdlg('PromptString','Select data for subset or xls file:',...
    'SelectionMode','multiple',...
    'InitialValue',handles.savevecs,...
    'ListString',s);

if ok==0 return; end

if isempty(find(handles.savevecs==handles.maindata.time_vec))
    handles.savevecs = [handles.savevecs handles.maindata.time_vec];
    handles.savevecs = sort(handles.savevecs);
end

if length(handles.savevecs) ~= handles.maindata.num_vecs
    set(handles.choose_data, 'String', 'Params Selected',...
        'BackgroundColor', [1 1 0]);
else
    set(handles.choose_data, 'String', 'Select Params',...
        'BackgroundColor', [236 233 216]/255);
end

guidata(hObject, handles);


% --- Executes on selection change in subset_under_eval.
function subset_under_eval_Callback(hObject, eventdata, handles)

handles.sel_subset = get(handles.subset_under_eval,'Value');

load_sel_subset(hObject, eventdata, handles)



function load_sel_subset(hObject, eventdata, handles)

s = get(handles.subset_under_eval, 'String');
handles.sel_subset = cell2mat(s(get(handles.subset_under_eval, 'Value')));
eval(['load ''' handles.file_under_eval ''' ' handles.sel_subset ]);
eval(['handles.maindata =' handles.sel_subset ';']);

handles.datastart = min(handles.maindata.data(:,handles.maindata.time_vec));
handles.displaystart = handles.datastart;
handles.startind =...
    find(handles.maindata.data(:,handles.maindata.time_vec)==handles.datastart);
handles.dataend = max(handles.maindata.data(:,handles.maindata.time_vec));
handles.displayend = handles.dataend;
handles.endind =...
    find(handles.maindata.data(:,handles.maindata.time_vec)==handles.dataend);
set(handles.start_time, 'String', num2str(handles.displaystart));
set(handles.end_time, 'String', num2str(handles.displayend));

if ~isfield(handles.maindata,'displayvecs')
    handles.maindata.displayvecs = [2 3 4 5 6];
end

s = handles.maindata.vec_names;
[newdisplayvecs,ok] = listdlg('PromptString','Select up to five parameters for the plots:',...
    'SelectionMode','multiple',...
    'InitialValue',handles.maindata.displayvecs,...
    'ListString',s,...
    'ListSize',[240 450],...
    'Name','Select Plot Parameters');

if ok==0 return; end

handles.maindata.displayvecs = [newdisplayvecs 2 3 4 5 6];
handles.maindata.displayvecs = handles.maindata.displayvecs(1:5);

eval([handles.sel_subset '=handles.maindata;']);
set(handles.popupmenu_axes1, 'String', handles.maindata.vec_names,...
    'Value', handles.maindata.displayvecs(1));
set(handles.popupmenu_axes2, 'String', handles.maindata.vec_names,...
    'Value', handles.maindata.displayvecs(2));
set(handles.popupmenu_axes3, 'String', handles.maindata.vec_names,...
    'Value', handles.maindata.displayvecs(3));
set(handles.popupmenu_axes4, 'String', handles.maindata.vec_names,...
    'Value', handles.maindata.displayvecs(4));
set(handles.popupmenu_axes5, 'String', handles.maindata.vec_names,...
    'Value', handles.maindata.displayvecs(5));

handles.savename = get(handles.ds_name_edit, 'String');
handles.savevecs = [1:handles.maindata.num_vecs];
set(handles.choose_data, 'String', 'Select Params',...
    'BackgroundColor', [236 233 216]/255);
set(handles.note, 'String', handles.maindata.note);

% Update handles structure
guidata(hObject, handles);

replot_all_axes(hObject, eventdata, handles)

function replot_all_axes(hObject, eventdata, handles)

for i=1:5; plot_axis(i, hObject, eventdata, handles); end

if get(handles.mag,'Value') == 1
    zoom on
    linkaxes([handles.axes1 handles.axes2 handles.axes3...
        handles.axes4 handles.axes5],'x');
else
    datacursormode on
    linkaxes([handles.axes1 handles.axes2 handles.axes3...
        handles.axes4 handles.axes5],'off');
end


% --- Executes on button press in set_upper_time.
function set_upper_time_Callback(hObject, eventdata, handles)

if get(handles.tip,'Value') == 1
    tipinfo = getCursorInfo(handles.dcm_obj);
    a = tipinfo.Position(1);
    if a <= handles.displaystart
        return
    end
else
    a = get(handles.axes1,'XLim'); a=a(2);
end
handles.displayend = a;
handles.endind = find(handles.maindata.data(:,handles.maindata.time_vec)<=...
    handles.displayend, 1, 'last');
handles.displayend =...
    handles.maindata.data(handles.endind,handles.maindata.time_vec);
set(handles.end_time, 'String', num2str(handles.displayend));

if get(handles.mag,'Value') == 1 & handles.returned == 0
    handles.returned = 1;
    set_lower_time_Callback(hObject, eventdata, handles)
    return
end
handles.returned = 0;

replot_all_axes(hObject, eventdata, handles)

guidata(hObject, handles);

% --- Executes on button press in set_lower_time.
function set_lower_time_Callback(hObject, eventdata, handles)

if get(handles.tip,'Value') == 1 & handles.returned == 0
    tipinfo = getCursorInfo(handles.dcm_obj);
    a = tipinfo.Position(1);
    if a >= handles.displayend
        return
    end
else
    a = get(handles.axes1,'XLim'); a=a(1);
end
handles.displaystart = a;
handles.startind = find(handles.maindata.data(:,handles.maindata.time_vec)...
    >=handles.displaystart, 1, 'first');
handles.displaystart =...
    handles.maindata.data(handles.startind,handles.maindata.time_vec);
set(handles.start_time, 'String', num2str(handles.displaystart));

if get(handles.mag,'Value') == 1 & handles.returned == 0
    handles.returned = 1;
    set_upper_time_Callback(hObject, eventdata, handles)
    return
end
handles.returned = 0;

replot_all_axes(hObject, eventdata, handles)

guidata(hObject, handles);

function txt = tip_select(nada,event_obj);
pos = get(event_obj,'Position');
txt = {['Time: ',num2str(pos(1))],...
    ['Value: ',num2str(pos(2))]};

% --- Executes on button press in add_line.
function add_line_Callback(hObject, eventdata, handles)

a = getCursorInfo(handles.dcm_obj);
if isempty(a)
    msgbox('Select a point first!')
    return
end

tipinfo = getCursorInfo(handles.dcm_obj);
t = tipinfo.Position(1);
t = [t t];

for chart=1:5
    y = eval(['get(handles.axes' num2str(chart) ',''YLim'');']);
    eval(['axes(handles.axes' num2str(chart) ')']);
    line(t,y,'color','r');
end

beep


% --- Executes on button press in clear_lines.
function clear_lines_Callback(hObject, eventdata, handles)

replot_all_axes(hObject, eventdata, handles)

function plot_axis(axis_num, hObject, eventdata, handles)

axis = num2str(axis_num);
eval(['handles.maindata.displayvecs(' axis ') = get(handles.popupmenu_axes'...
    axis ', ''Value'');']);

if round(axis_num/2)~=axis_num/2; axisloc = 'left';
else axisloc = 'right'; end

eval(['axes(handles.axes' axis ');'])

eval(['dplot = plot(handles.maindata.data(:,handles.maindata.time_vec)'...
    ',handles.maindata.data(:,get(handles.popupmenu_axes' axis...
    ', ''Value'')));']);
if axis_num ~= 5
    set(gca, 'XGrid', 'on',...
        'YGrid', 'on',...
        'XTickLabel','',...
        'XLim', [handles.displaystart handles.displayend],...
        'YAxisLocation', axisloc);
else
    set(gca, 'XGrid', 'on',...
        'YGrid', 'on',...
        'XLim', [handles.displaystart handles.displayend],...
        'YAxisLocation', axisloc);
end


x=get(gca, 'XLim'); y=get(gca, 'YLim');
eval(['name = get(handles.popupmenu_axes' axis ', ''String'');']);
titletext = eval(['name{get(handles.popupmenu_axes' axis ', ''Value'')};']);
text(x(1) + .01*(x(2)-x(1)), y(2) - .001*(y(2)-y(1)),...
    titletext,...
    'fontsize', 8,...
    'HorizontalAlignment','left',...
    'VerticalAlignment','top',...
    'Color',[0 .5 0],...
    'FontWeight', 'bold',...
    'Interpreter', 'none')

guidata(hObject, handles);

% --- Executes on button press in DV1.
function DV1_Callback(hObject, eventdata, handles)

% Hint: get(hObject,'Value') returns toggle state of DV1

only_one_button(1 , 'DV', hObject, eventdata, handles)


% --- Executes on button press in IV1.
function IV1_Callback(hObject, eventdata, handles)

only_one_button(1 , 'IV', hObject, eventdata, handles)


% --- Executes on button press in DV2.
function DV2_Callback(hObject, eventdata, handles)

only_one_button(2 , 'DV', hObject, eventdata, handles)


% --- Executes on button press in IV2.
function IV2_Callback(hObject, eventdata, handles)

only_one_button(2 , 'IV', hObject, eventdata, handles)


% --- Executes on button press in DV3.
function DV3_Callback(hObject, eventdata, handles)

only_one_button(3 , 'DV', hObject, eventdata, handles)


% --- Executes on button press in IV3.
function IV3_Callback(hObject, eventdata, handles)

only_one_button(3 , 'IV', hObject, eventdata, handles)


% --- Executes on button press in DV4.
function DV4_Callback(hObject, eventdata, handles)

only_one_button(4 , 'DV', hObject, eventdata, handles)


% --- Executes on button press in IV4.
function IV4_Callback(hObject, eventdata, handles)

only_one_button(4 , 'IV', hObject, eventdata, handles)


% --- Executes on button press in DV5.
function DV5_Callback(hObject, eventdata, handles)

only_one_button(5 , 'DV', hObject, eventdata, handles)


% --- Executes on button press in IV5.
function IV5_Callback(hObject, eventdata, handles)

only_one_button(5 , 'IV', hObject, eventdata, handles)


function only_one_button(caller , DVIV, hObject, eventdata, handles)

for i=1:5
    if i ~= caller
        eval(['set(handles.' DVIV num2str(i) ', ''Value'', 0);']);
    end
    eval(['handles.' DVIV '=' num2str(caller) ';']);
end

guidata(hObject, handles);


% --- Executes on button press in plot_DVIV.
function plot_DVIV_Callback(hObject, eventdata, handles)

if handles.DV == 0 | handles.IV == 0
    msgbox('Select independent and dependent variables first!')
    return
end



get(handles.axes1,'XLim');

rows = [num2str(handles.startind) ':' num2str(handles.endind)];

idata = eval(['handles.maindata.data(' rows ','...
    num2str(handles.maindata.displayvecs(handles.IV)) ');']);
ddata = eval(['handles.maindata.data(' rows ','...
    num2str(handles.maindata.displayvecs(handles.DV)) ');']);
iname = cell2mat(eval(['handles.maindata.vec_names('...
    num2str(handles.maindata.displayvecs(handles.IV)) ');']));
dname = cell2mat(eval(['handles.maindata.vec_names('...
    num2str(handles.maindata.displayvecs(handles.DV)) ');']));

figure;
plot(idata,ddata,'.')
xlabel(iname, 'Interpreter', 'none'); ylabel(dname, 'Interpreter', 'none')


function note_Callback(hObject, eventdata, handles)

handles.maindata.note = get(handles.note, 'String');
eval([handles.sel_subset '=handles.maindata;']);
eval(['save ''' handles.file_under_eval ''' ' handles.sel_subset ' -append']);


% --- Executes on button press in choose_new_data.
function choose_new_data_Callback(hObject, eventdata, handles)

TPS_data_utility_OpeningFcn(hObject, eventdata, handles)


% --- Executes on button press in update_subset.
function update_subset_Callback(hObject, eventdata, handles)



disptime = get(handles.axes1,'XLim');
settime = [handles.displaystart handles.displayend];

if disptime ~= settime
    warndlg('Chart times do not match: click "Set" buttons first',...
        'Inconsistent time range...')
    return
end

eval([handles.sel_subset '=handles.maindata;'])
rows = [num2str(handles.startind) ':' num2str(handles.endind)];
columns  = ':';
eval([handles.sel_subset '.data=handles.maindata.data(' rows ',' columns ');']);
totrows = eval(['size(' handles.sel_subset '.data,1);']);
eval([handles.sel_subset '.samples=' num2str(totrows) ';']);
high = eval([handles.sel_subset '.data(2:end,' num2str(handles.maindata.time_vec) ');']);
low = eval([handles.sel_subset '.data(1:end-1,' num2str(handles.maindata.time_vec) ');']);
eval([handles.sel_subset '.samp_rate_ave=' num2str(mean(high-low)) ';']);

eval(['save ''' handles.file_under_eval ''' ' handles.sel_subset ' -append']);


% --- Executes on button press tip.
function tip_Callback(hObject, eventdata, handles)
% hObject    handle to tip (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of tip
if get(handles.tip,'Value') == 1
    set(handles.mag,'Value',0);
    datacursormode on
    linkaxes([handles.axes1 handles.axes2 handles.axes3...
        handles.axes4 handles.axes5],'off');
else
    set(handles.mag,'Value',1);
    zoom on
    linkaxes([handles.axes1 handles.axes2 handles.axes3...
        handles.axes4 handles.axes5],'x');
end


% --- Executes on button press in mag.
function mag_Callback(hObject, eventdata, handles)

if get(handles.mag,'Value') == 1
    set(handles.tip,'Value',0);
    zoom on
    linkaxes([handles.axes1 handles.axes2 handles.axes3...
        handles.axes4 handles.axes5],'x');
else
    set(handles.tip,'Value',1);
    datacursormode on
    linkaxes([handles.axes1 handles.axes2 handles.axes3...
        handles.axes4 handles.axes5],'off');
end


% --- Executes on button press in pushbutton18.
function pushbutton18_Callback(hObject, eventdata, handles)


disptime = get(handles.axes1,'XLim');
settime = [handles.displaystart handles.displayend];

if disptime ~= settime
    warndlg('Chart times do not match: click "Set" buttons first',...
        'Inconsistent time range...')
    return
end

s = handles.maindata.vec_names;
[ws_vecs,ok] = listdlg(...
    'PromptString','Select data for exporting as workspace vectors:',...
    'SelectionMode','multiple',...
    'InitialValue',[handles.maindata.time_vec handles.maindata.displayvecs],...
    'ListString',s);

if ok==0 return; end

for i = 1:length(ws_vecs)
    data = handles.maindata.data(handles.startind:handles.endind,ws_vecs(i));
    assignin('base',cell2mat(handles.maindata.vec_names(ws_vecs(i))),data);
end

% --- Executes on button press in bode.
function bode_Callback(hObject, eventdata, handles)
% hObject    handle to bode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if handles.DV == 0 || handles.IV == 0
    msgbox('Select independent and dependent variables first!')
    return
end

err_bands = get(handles.bode_err_bands,'Value');
SD = str2num(get(handles.SD,'String'));

get(handles.axes1,'XLim');

rows = [num2str(handles.startind) ':' num2str(handles.endind)];

indata = eval(['handles.maindata.data(' rows ','...
    num2str(handles.maindata.displayvecs(handles.IV)) ');']);
outdata = eval(['handles.maindata.data(' rows ','...
    num2str(handles.maindata.displayvecs(handles.DV)) ');']);
iname = cell2mat(eval(['handles.maindata.vec_names('...
    num2str(handles.maindata.displayvecs(handles.IV)) ');']));
dname = cell2mat(eval(['handles.maindata.vec_names('...
    num2str(handles.maindata.displayvecs(handles.DV)) ');']));

hz = 1/handles.maindata.samp_rate_ave;

% System Identification
z_resp = iddata(outdata,indata,1/hz);

%Spectral Analysis (SPA)
GS_resp=spafdr(z_resp);

% Coherence
[coh_outdata,freq_outdata]=mscohere(indata,outdata);

freq_outdata=(freq_outdata.*hz);

if err_bands == 0
    fig_no_sd = figure;
    set(fig_no_sd,'Name',['Input: ',iname,', Output: ',dname])
    
    subplot(3,1,1);
    plot(freq_outdata,coh_outdata,'-b')
    set(gca,'XLim',[0.8,40],'XScale','log','XGrid','on','YGrid','on')
    ylabel('Coherence')
    
else
    fig_sd = figure;
    set(fig_sd,'Name',['Input: ',iname,', Output: ',dname])
    
    subplot(3,1,1);
    plot(freq_outdata,coh_outdata,'-b')
    set(gca,'XLim',[0.8,40],'XScale','log','XGrid','on','YGrid','on')
    ylabel('Coherence')
end

%Magnitude & Phase
[mag,phase,w,sd_mag,sd_phase]=bode(GS_resp);

%Magnitude and Phase Plots
if err_bands == 0
    mid=20*log10(mag(:));
    
    figure(fig_no_sd)
    subplot(3,1,2);
    semilogx(w,mid,'-b');
    set(gca,'XLim',[0.8,40],'XScale','log','XGrid','on','YGrid','on')
    ylabel('Magnitude (dB)')
    
    if get(handles.wrap_phase,'Value')==1
        mid=wrapTo180(phase(:));
    else
        mid=(phase(:));
    end
    
    figure(fig_no_sd)
    subplot(3,1,3);
    semilogx(w,mid,'-b');
    set(gca,'XLim',[0.8,40],'XScale','log','XGrid','on','YGrid','on')
    set(gca,'YLim',[-360,180],'ytick',[-360 -270 -180 -90 0 90 180])
    ylabel('Phase (deg)')
    xlabel('Frequency (rad/s)')
    
else
    mid=20*log10(mag(:));
    sd_hi=20*log10(mag(:)+SD*sd_mag(:));
    sd_lo=20*log10(mag(:)-SD*sd_mag(:));
    
    figure(fig_sd)
    subplot(3,1,2);
    semilogx(w,mid,'-b');
    fill(vertcat(w,w(end:-1:1)),vertcat(sd_hi,sd_lo(end:-1:1)),'b','FaceAlpha', 0.5)
    hold on
    set(gca,'XLim',[0.8,40],'XScale','log','XGrid','on','YGrid','on')
    ylabel('Magnitude (dB)')
    hold off
    
    if get(handles.wrap_phase,'Value')==1
        mid=wrapTo180(phase(:));
        sd_hi=wrapTo180(phase(:)+SD*sd_phase(:));
        sd_lo=wrapTo180(phase(:)-SD*sd_phase(:));
    else
        mid=(phase(:));
        sd_hi=(phase(:)+SD*sd_phase(:));
        sd_lo=(phase(:)-SD*sd_phase(:));
    end
    
    figure(fig_sd)
    subplot(3,1,3);
    semilogx(w,mid,'-b');
    fill(vertcat(w,w(end:-1:1)),vertcat(sd_hi,sd_lo(end:-1:1)),'b','FaceAlpha', 0.5)
    hold on
    set(gca,'XLim',[0.8,40],'XScale','log','XGrid','on','YGrid','on')
    set(gca,'YLim',[-360,180],'ytick',[-360 -270 -180 -90 0 90 180])
    ylabel('Phase (deg)')
    xlabel('Frequency (rad/s)')
    hold off
end

if get(handles.bode_marg_est,'Value')==1
    pmgm = figure;
    set(pmgm,'Name',['Input: ',iname,', Output: ',dname])
    margin(mag,phase,w)
end


% --- Executes on button press in bode_marg_est.
function bode_marg_est_Callback(hObject, eventdata, handles)
% hObject    handle to bode_marg_est (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of bode_marg_est


% --- Executes on button press in bode_err_bands.
function bode_err_bands_Callback(hObject, eventdata, handles)
% hObject    handle to bode_err_bands (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of bode_err_bands



function SD_Callback(hObject, eventdata, handles)
% hObject    handle to SD (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of SD as text
%        str2double(get(hObject,'String')) returns contents of SD as a double


% --- Executes during object creation, after setting all properties.
function SD_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SD (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in wrap_phase.
function wrap_phase_Callback(hObject, eventdata, handles)
% hObject    handle to wrap_phase (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of wrap_phase


