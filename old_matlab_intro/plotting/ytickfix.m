function ylabelfix(varargin)
% YLABELFIX - converts from scientific notation to desired format fmt
%
% ylabelfix(axis_handle,fmt)
%
% If no input argument, then assume gca and round to nearest integer
% If input argument, then
%       handle used to specify axes object
%       char array is used to use format string to format existing labels

if nargin == 0
    axis_handle = gca;
    fmt = '%d';
elseif nargin == 1
    input_var = varargin{1};
    if ischar(input_var)
        fmt = input_var;
    elseif isnumeric(input_var)
        axis_handle = input_var;
        
    end
else % Two inputs
    axis_handle = varargin{1};
    fmt = varargin{2};
end

if ~strcmp(fmt(1),'%')
    error('Must use % at beginning of format string!');
    return
end

if ~ishandle(axis_handle)
    error('Must be a valid handle');
end

set(axis_handle,'YTickLabel',num2str(get(axis_handle,'YTick')','%d'))


