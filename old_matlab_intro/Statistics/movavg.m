function fdata=movavg(data,windowSize)
% fdata=movavg(data,windowSize)
%
% Run with no output to get plots
B=ones(1,windowSize);
A=windowSize;

ftemp=filtfilt(B,A,data);
id=1:length(data);
if nargout==0
    figure(gcf), clf
    plot(id,data,'ro',id,ftemp,'b-')
    legend('Raw Data','Filtered Data')

else
    fdata=ftemp;
end



