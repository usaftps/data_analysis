function varargout=yylabel(varargin)
%%YYLABEL Same as YLABEL but applies to right y-axis of plotyy plot

if nargin == 0, error('Not enough input arguments'), end

if ishandle(varargin{1})  % ylabel will work if the correct axis is active
    right_axis=varargin{1}; % User found it for us, almost pointless to use this then
    leftover=varargin(2:end);
else
    fig=get(gca,'Parent');  % Which figure is this axis
    all_axes=findobj(fig,'Type','axes');
    right_axis=findobj(all_axes,'YAxisLocation','right');
    if isempty(right_axis)
        error('This figure does not appear to contain a plot created using plotyy')
    end
    right_axis=right_axis(1);  % If more something wierd's happening, but this may avoid an error
    leftover=varargin(1:end);
end

ylabel(right_axis,leftover{:})

if nargout>0
    varargout{1}=right_axis;
end


