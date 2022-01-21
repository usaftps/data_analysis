% This script summarizes the materials that are covered during the live
% console basic demonstration.
%
% Written by Lt Col Juan "Silv" Jurado, USAF TPS
% Updated June 2021 by Mr. Aaron Wenner, USAF TPS

clear; clc; close all;

% First, anything with a "%" on the start of the line is considered a
% comment and not interpreted by the compiler. Use this to comment your own
% code for future reference.
% Ctrl + R/Ctrl + T to Comment/Uncomment

% Auto-Indent
% Ctrl + I

% Run all/Run Selected
% F5 / F9

% Kill Command
% Ctrl + C


% If you want a result to NOT be displayed on the console, end your code
% line with ";", otherwise, the value of the set variable will be
% displayed.

%% Basic arrays
x = [1, 2, 5, 6]; % A 1D numeric array, manually filled in
length(x); % The length of the array
X = [1, 2, 3; 4, 5, 6; 7, 8, 9; 10, 11, 12]; % A 2D array (matrix) 
[num_rows, num_cols] = size(X); % The shape of the array

 % Print some info to console
fprintf('The length of x is: %d\n', length(x));
fprintf('Matrix X is %d by %d:\n',num_rows, num_cols);
disp(X);

% Create an array from a range of numbers
odd_numbers = 1:2:100;
even_numbers = 2:2:100;

 % Create a vector "time" ranging from 0 to 1 in 200 even steps
time = linspace(0,1,200);

% Access entries in an array
time(50)
time(1)
time(end)
time(end-1)

% At what entry does time = 0.5? Many methods to find out.
idx1 = find(time == 0.5, 1, 'first');
idx2 = find(time <= 0.5, 1, 'last');
idx3 = find(time >= 0.5, 1, 'first');
[~,idx4] = min((time - 0.5).^2);
time(idx1)
time(idx2)
time(idx3)
time(idx4)

% Crop the time array such that only times less than 0.5 are contained in 
% in the cropped version
idx = time < 0.5;
new_time = time(idx);

%% Cell arrays 
% Cell arrays are like numeric arrays but can contain any type of data, not
% just numbers
my_cell = {'welcome', 'to', 'tps', time, new_time};
 
% We can crop the array using indexing and ()
crop_cell = my_cell(1:3);

% To access the contents of a cell, we use {}
x = my_cell{4};

%% Structures
% MATLAB provides an easy way to read/write data in the form of structures
s = load('sample_data/sample_structure.mat');
fieldnames(s.data)

% Let's look at the structure "turns" contained inside the structure "data"
% First we'll pre-allocate a zero-array to store data in the loop
num_turns = length(s.data.turns); % Number of "turns" in the turns structure
avg_alts = zeros(num_turns,1); % An array of zeros that is num_turns x 1
for turn = 1:num_turns
    this_turn = s.data.turns(turn);
    this_gps_alt = this_turn.gps_altitude_ft;
    mean_alt = mean(this_gps_alt);
    avg_alts(turn) = mean_alt; % Store this mean_alt for later
    fprintf('Turn #%d, average altitude was %0.3f ft\n',turn,mean_alt) 
end

% Now let's save our own structure
myData.altitudes = avg_alts;
myData.date = sprintf('%d-%d-%d',month(today), day(today), year(today));
myData.original_data = s.data.turns;

% Now let's save the myData variable to a .MAT file 
save('class_data.mat','myData');

%% Vector math
% Matlab is built around doing linear algebra, so all linear algebra math
% is built-in natively. As a matter of fact, to get it to do non-linear
% algebra, we use the special character "."

x = linspace(-5,5,100); % Define a vector x spanning -5, to 5 in 100 steps
size(x); % note linspace creates a row vector (1 x N)
size(x'); % to transpose, use ', now it is a column vector (N x 1)
% y1 = (x - 3)^2; % define y = f(x) = (x - 3)^2. why is there an error?
% Answer: there is no linear algebra definition for vector^2, what we want
% is to raise every entry in (x - 3) to the power of 2
y2 = (x - 3).^2; 

% Now, let's do some basic linear algebra
x1 = [5; 3; 2]; % 3 x 1 column vector
x2 = [7; 4; 2]; 
euc_dist1 = norm(x1-x2);
euc_dist2 = sqrt(sum((x1-x2).^2));

% Define a 3 x 3 matrix to multiply with x1
M = [3, 4, 5;
     1, 3, 6;
     0, 1, 0];
y1 = M*x1; 

% How about the inverse of M?
M_inv1 = inv(M);
M_inv2 = M^-1;

% There are TONS of many other built-in functions, which can be discovered
% via the "help" and "doc" functions as well as Mathworks online and
% Google.



