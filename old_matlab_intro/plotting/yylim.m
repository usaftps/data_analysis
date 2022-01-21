function out=yylim(varargin)
%YYLIM Same as YLIM but applies to right y-axis of plotyy plot

if nargin > 0 && length(varargin{1})==1 && ishandle(varargin{1})  % ylim will work if the correct axis is active
    right_axis=varargin{1}; % User found it for us, almost pointless to use this then
    leftover=varargin(2:end);
    fig=get(right_axis,'Parent');  % Which figure is this axis
    all_axes=findobj(fig,'Type','axes');
    left_axis=findobj(all_axes,'YAxisLocation','left');
else
    fig=get(gca,'Parent');  % Which figure is this axis
    all_axes=findobj(fig,'Type','axes');
    right_axis=findobj(all_axes,'YAxisLocation','right');
    left_axis=findobj(all_axes,'YAxisLocation','left');
    if isempty(right_axis)
        error('This figure does not appear to contain a plot created using plotyy')
    end
    right_axis=right_axis(1);  % If more something wierd's happening, but this may avoid an error
    if nargin > 0
        leftover=varargin(1:end);
    end
end
if nargin==0
    % Provide ylim of axis
    out=ylim(right_axis);
else
    % Set ylim of axid
    ylim(right_axis,leftover{:})
    % Set Axis the same
    divs=size(get(left_axis,'YTicklabel'),1)-1;
    ax1=right_axis;    
    ylimits = get(ax1,'YLim');    
    yinc = (ylimits(2)-ylimits(1))/divs;
    % Now set the tick mark locations.
    set(ax1,'YTick',[ylimits(1):yinc:ylimits(2)],'YTickLabelMode','auto')
    hyy=[left_axis;right_axis];
    linkaxes(hyy,'x') % Changing one will change the other (there's really two one behind the other)

end
