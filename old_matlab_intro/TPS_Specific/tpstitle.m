function [Htitle,ht]=tpstitle(varargin)
%TPSTITLE Create a centered master title and two columns of title text
%
%                  tpstitle(bigtitle, coltext)
%   [Htitle,Htext]=tpstitle(bigtitle, coltext, fonts, ratios)
%                  tpstitle(Ha,...)
%
%  bigtitle  - centered title string
%  coltext   - cell array of cells containing the columns of text
%  fonts     - vector of [title_font column_text_font]. default is [12 11]
%  Ha        - handle of axis to place atop, default is current axis
%  Htitle    - title handle
%  Htext     - handle of text within each column
%
% Example:
%
%     Hf=figure(1); clf
%     plot(0:10), Ha=gca; grid on, set(Ha,'Box','on','FontName','Arial')
%     Ht=get(Ha,'title');
%     set(Ht,'FontWeight','bold')
%     xlabel('Angle of Attack, \alpha (deg)','FontWeight','bold')
%     ylabel('Lift Coefficient, C_L','FontWeight','bold')
%     bigtitle='Gilbert XF-20';
%     coltext={{...   % first cell contains first column
%         'Configuration: Cruise', ...
%         'Pressure Altitude: 10,000 feet', ...
%         'Weight: 57,000 pounds', ...
%         'CG: 23.9 percent',...
%         'Wing Reference Area: 548 ft^{ 2}' ... % ^ is superscript
%         },{...      % second cell contains second column
%         'Data Basis: Flight Test', ...
%         'Test Dates: 2 Sep 50', ...
%         'Test Day Data', ...
%         'W/\delta = 82,884 pounds', ...  \delta is a TeX command
%         ' '}};      % a cell of cells (must have equal rows)
%     fonts=[14 12]; ratios=[.1 .65];
%     [Htitle, Htext]=tpstitle(bigtitle, coltext, fonts, ratios);
%     set([Htitle; Htext; gca],'FontName','Arial') %  To change the fonts
%     margins=[-.7 -.7 0 -.25]; % not useful for pngs
%     tpscrop(Hf,[9 6],'Gilbert','png',[],'portrait') % scales & saves
%     tpscrop(Hf,[9 6],'Gilbert','pdf',margins,'portrait') % scales & saves
%
% written by: Lt Col Tim Jorris, TPS/CS, July 2009

if nargin==0  % Run the example
    Hf=figure(1); clf
    plot(0:10); Ha=gca; 
    %clf
    %[AX,H1,H2] = plotyy(1:10,1:10,10:100,10:100);
    %Ha=AX(1);
    grid on, set(Ha,'Box','on','FontName','Arial')
    Ht=get(Ha,'title');
    set(Ht,'FontWeight','bold')
    xlabel('Angle of Attack, \alpha (deg)','FontWeight','bold')
    ylabel('Lift Coefficient, C_L','FontWeight','bold')
    bigtitle='Gilbert XF-20';
    coltext={{...   % first cell
        'Configuration: Cruise', ...
        'Pressure Altitude: 10,000 feet', ...
        'Weight: 57,000 pounds', ...
        'CG: 23.9 percent',...
        'Wing Reference Area: 548 ft^{ 2}' ... % space in exponent looks better
        },{...      % second cell
        'Data Basis: Flight Test', ...
        'Test Dates: 2 Sep 50', ...
        'Test Day Data', ...
        'W/\delta = 82,884 pounds', ...
        ' '}};      % a cell of cells
    fonts=[14 12]; ratios=[.15 .65];
    % tpstitle(bigtitle, coltext, fonts, ratios)
    varargin={bigtitle, coltext, fonts, ratios};
end
%%
% Pick apart the user inputs
[Ha,bigtext,coltext,fonts,ratio]=getinputs(varargin{:});
if Ha==0; return, end
%%
% Automatic calculations based on user input
numcols=length(coltext);
numrows=length(coltext{1});
% Ratios; create a bin for each column
buffer=.01;
ratio(1)=ratio(1)+buffer;
bigfont=fonts(1); colfont=fonts(2);
% Make the default title, xlabel, ylabel, match the column font size
set(Ha,'FontSize',colfont)
% Create the Title, with space holders for the column's text
Ht_cell=cell(3+numrows,1); 
% 1st contains text, the others are simply the right size
Ht_cell([1:2,end])={sprintf('{\\fontsize{%f}%s}',bigfont,bigtext), ...
              sprintf('{\\fontsize{%f}  }',colfont/2), ... % blank line
              sprintf('{\\fontsize{%f}  }',colfont/2)};    % blank line
for i=1:numrows
    Ht_cell(2+i)={sprintf('{\\fontsize{%f} }',colfont)};   % correct font
end
Ht=title(Ht_cell); Ht_pos=get(Ht,'Pos');
% Now use the size of the Title to create templates for the columns
ht=zeros(numcols,1);
if strcmpi(get(Ha,'XDir'),'normal')
    firstpos=min(xlim(Ha)); % the Position is on data, so 'normal' matters
else
    firstpos=max(xlim(Ha));
    ratio=-ratio;
end
tpstitle_tag='tpstitle_text';
% Remove old version if they exist, but a move accured
kid_text=findobj(gca,'Type','text');
if ~isempty(kid_text)
    old_tpstitle=findobj(kid_text,'Tag',tpstitle_tag);
    if ~isempty(old_tpstitle)
        delete(old_tpstitle)
    end
end
% Remove the Title text, but keep the fontsize for spacing
for i=1:numcols % Fill in the text; 1,2 and end are copied from Title
    ht(i)=copyobj(Ht,Ha);
    set(ht(i),'Tag',tpstitle_tag)
    OneCol=Ht_cell; % 1st is Title, 2nd & last are line skips
    OneCol(1)={sprintf('{\\fontsize{%f} }',bigfont)};
    for j=1:numrows        
        OneCol{2+j}=sprintf('{\\fontsize{%f}%s}',colfont,coltext{i}{j});
    end    
    set(ht(i),'String',OneCol,'Hor','left', ...
        'Pos',[firstpos+ratio(i)*diff(xlim(Ha)), Ht_pos(2), Ht_pos(3)])
end
if nargout > 0, Htitle=Ht; end

function [Ha,bigtitle,coltext,fonts,ratio]=getinputs(varargin)
% Figure out if a valid figure handle was provide by user, or use current
bigtitle=''; coltext={'',''};
if nargin==0
    disp(['Inputs are required: type ''doc ',mfilename,''' for more help.'])
    Ha=0;
elseif nargin > 0 && length(varargin{1})==1 && ishandle(varargin{1})
    Ha=varargin{1};
    varargin(1)=[]; 
elseif nargin > 0 && length(varargin{1})==1 && ~ishandle(varargin{1}) 
        error('Invalid axis handle in first argument')
else
    Ha=gca;
end
% tpstitle(bigtitle, coltext)
lenvar=length(varargin);
fonts=[12,11];

if lenvar < 2
    disp('''bigtitle'' and ''boxtitles'' are required inputs'), Ha=0; return
else
    bigtitle=varargin{1};    
    coltext =varargin{2};    
    if lenvar >= 3, fonts=varargin{3};  end
    numcols=length(coltext);
    if lenvar >= 4
        ratio=varargin{4};
    else
        ratio=[0:1/numcols:(1-1/numcols)];
    end
end