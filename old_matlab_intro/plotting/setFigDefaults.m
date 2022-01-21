% This script initializes the figure and axes interpreters to make the
% figure font and font size more appropriate for publishing in reports.
%
% Written by Juan "Silv" Jurado
set(groot, 'DefaultTextInterpreter','latex');
set(groot, 'DefaultLegendInterpreter', 'latex');
set(groot, 'defaultAxesTickLabelInterpreter','latex'); 

set(groot,'DefaultAxesFontSize',16);
set(groot,'DefaultTextFontSize',16);
set(groot,'defaultAxesFontName','Helvetica');
set(groot,'defaultTextFontName','Helvetica');