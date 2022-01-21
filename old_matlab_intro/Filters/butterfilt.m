function fdata=butterfilt(data,border,bcutoff,varargin)
% fdata=butterfilt(data,border,bcutoff,type)
%
% data    - [time, signal] 
% border  - order of the butterworth filter, 4 is good for flight test
% bcutoff - cutoff frequency in Hz, time in seconds must be first column
%
% written by: Lt Col Tim "Boomer" Jorris, TPS/CS, Aug 2009
%
% See also BUTTER, FILT, FILTFILT

% Run with no output to get plots

% load doublet
time   =data(:,1);
signal =data(:,2:end);

dt=time(2)-time(1);
sample=1/dt; %---- about Hz data

Nyquist=0.5*sample;

if max(bcutoff) > Nyquist
    error([...
    'Selected cutoff frequency is greater than the Nyquist fequency.', char(10), ...
    'Thus you are selecting to observe a frequency that is not possible with your data.', char(10), ...
    'Please select a cutoff frequency equal to or less than ',num2str(Nyquist),' Hz'])
end

[B,A]=butter(border,bcutoff/(0.5*sample),varargin{:});
    
ftemp=filtfilt(B,A,signal);

if nargout==0
    plot(time,signal,'rx',time,ftemp,'b-')
    legend('Raw Data','Filtered Data')
    figure(gcf)
else
    fdata=ftemp;
end



