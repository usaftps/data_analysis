function path_and_file = simplegetfile
% SIMPLEGETFILE uses uigetfile and formats the output to allow for direct
% entry into a function requiring a pathname
[filen,pathn] = uigetfile('*.*');
if filen == 0
    error('FileSelection:noFileSelected','You didn''t select a file!');
    return
end
path_and_file = [pathn,filen];