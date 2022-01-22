%% TF 6510: Introduction to Matlab
% Written by Lt Col Juan "Silv" Jurado

%% Introduction
% In this example, we will read a sample C-12 Data Aquisition System (DAS)
% file, extract a couple of data parameters by using the event markers in
% the data stream, and produce a TPS-quality PDF figure ready to go into a
% test report. 
% 
% Use this example to get ideas for the "choose your own adventure"
% projects during the course. Feel free to copy/paste any code you find
% useful in the completion of your own project. 

%% Code
% It is always a good idea to clear out the console, close all figures, and
% clear all variables when running a script.
clc; close all; clear;

% Import C-12 DAS data, which is formatted as a CSV file. My technique is
% to use Matlab's own 'readtable' function, which reads CSVs quickly and
% produces a Matlab 'table' object that is designed to work with data, can
% be exported back out to a CSV or Excel easily via the 'writetable"
% function and can be converted to a timetable to interpolate between rows
% and/or combine with other sources of information via the time tags. 
fileName = 'sample_data/sample_C12_DAS.csv';
data = readtable(fileName);

% The data we're for is the C-12's "Phugoid Mode" response, which is
% a decaying interchange between airspeed and altitude over a relatively
% long period of time (minutes) after having executed a "Pitch Doublet"
% manuever.  We want to plot altitude versus time, let's pull off those two
% vectros from the DAS data. My technique is to minimize hardcoding values
% and make as many things "definable" variables as possible, so that I can
% turn my scripts into functions later on if needed.
timeName = 'Delta_Irig'; % Name of "time" in the C-12 DAS
altitudeName = 'ADC_ALT_29'; % Name of "pressure altitude" in the C-12 DAS

% Now we can use the variables timeName and altitudeName to pull off the
% desired parameters from the data table "data". 
time = data.(timeName); 
altitude = data.(altitudeName);

% Up to this point, we have time and altitude for the ENTIRE mission. We
% now need to trim the data to the time window of interest, which is done
% by looking for "Event Markers." The Test Conductor has informed us that 
% the Phugoid FTT was executed somewhere between event markers 7 and 9. We
% were also told the name of the data stream that contains events in the
% C-12 DAS is "ICU_EVNT_CNT".
eventName = 'ICU_EVNT_CNT'; % Name of "events" in C-12 DAS
allEvents = data.(eventName); % Event data vector

% Using that information, let's define an event vector. The ":" operator 
% essentially means "through."
myEvents = 7:9; % A vector of event numbers 7 through 10
nEvents = length(myEvents); % Compute the length of the above vector
ids = zeros(nEvents,1); % Preallocate an empty vector with the same length 

% For each event, use the "find" function to figure out what row in the
% DAS data stream corresponds to the start of each event.
for ii = 1:nEvents
    ids(ii) = find(allEvents==myEvents(ii),1);
end
idxStart = ids(1); % The starting index is the index of the first event
idxEnd = ids(end); % The final index is the index of the last event

% Now that we have the row numbers, we can use Matlab's logical indexing
% feature to trim the time and altitude vectors to the desired window and
% are now ready to make our plot.
eventTime = time(idxStart:idxEnd);
eventAlt = altitude(idxStart:idxEnd);

%setFigDefaults; % A simple script to get fonts and font sizes ready
f = figure('Units','inches')  ; % Instantiate a figure object
f.Position = [0 0 8 6]; % [x, y, width, height] in inches

% Plot eventTime vs. eventAlt and set the line style to solid, the line
% color to blue, and the line width to 2.
plot(eventTime,eventAlt,'b-','LineWidth',2);
grid minor; % Turn on the grid with minor "ticks"
xlabel('Sortie Time [s]'); % Set the label of the x axis
ylabel('Pressure Altitude, $H_c$ [ft]'); % Set the label of the y axis

% Now we can use a TPS-specific title for flight test figures. We define a
% big title and a set of smaller subtitles broken into columns to
% include all necessary info about the data we collected. You can have more
% than two columns, and each column can have a different number of rows.
% However, keeping it to about 2 columns with 3-4 rows each seems to
% produce the best results. If you need more room, change the f.Position
% values in line 74.

bigTitle = '\bf C-12 Huron Phugoid Response'; % Define the "big" title
% Define the first (left) column of extra info
col1 = {'Configuration: Cruise';
        'Airspeed: 160 KIAS';
        'Weight: 11,500 lbs'};
% Define the second (right) column of extra info
col2 = {'Data Basis: Flight test';
        'Test Dates: 12 Jan 2021';
        'Test Day Data'};
subtitles = {col1,col2}; % Combine the columns into a single cell array 
testPointTitle(bigTitle,subtitles); % Feed info to the TPS title function

% Finally, we'll export the figure as a PDF.
% This function provides a quick and easy way to trim the white borders and
% preserve the vector graphic information.
%exportAsPdf('phugoid');





