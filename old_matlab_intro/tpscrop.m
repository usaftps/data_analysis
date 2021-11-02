function tpscrop(varargin)

%TPSCROP Size and crop figure and save as an eps or pdf
%
%   tpscrop(img_size, filename)
%   tpscrop(img_size, filename, fmt)
%   tpscrop(img_size, filename, fmt, margins)
%   tpscrop(img_size, filename, fmt, margins, orient)
%   tpscrop(Hf, ...)
%
% img_size - width and height in inches, e.g. [6.5 3]
% filename - file name to save as, don't need extension
% fmt      - 'eps','pdf','png', or 'emf' default is 'eps' if not provided
% margins  - [left right top bottom] in inches.
%            -- Positive margins increase outward, thus creating more white
%               space, or allows you to "see" a portion of a plot that may
%               be cut off. 
%            -- Negative margins move the edges inward, thus eliminating
%               white space.
% orient   - 'portrait' or 'landscape'. 'landscape' rotates the image.
%            img_size and margins remain as if viewing with title on top.
%            This is only valid for 'eps' files, pdf's don't rotate. The
%            default is 'portrait' unless the width exceed 8.5 then the
%            default switches to 'landscape'
% Hf       - figure handle, current figue is default if not provided
%
% The purpose is to remove the default whitespace around a figure,
% and to ensure the final saved file is the size specified by the user.
% This avoids cropping and bad resizing in Word or LaTeX. The only two
% formats supported are .eps and .pdf.  An .eps file can be imported into
% Word and retains better resolution than a .png.  A .pdf can be used by
% LaTeX, when used with the pdfLatex compiler.
%
% Example:
% 
%     figure(1); clf, fontsize=14;
%     set(gca,'FontSize',fontsize)
%     contourf(100*peaks(20),20); colormap jet
%     title('Contour Plot of Peaks')
%     Hc=colorbar; figure(1); set(Hc,'FontSize',fontsize)
%     filename='peaks'; % extension is added automatically
%     img_size=[6.5 4]; % [width height];
%     tpscrop(img_size,filename) % minimum inputs requred
%     margins=[0 .2 0 0]; % pdf needs a larger right margin
%     tpscrop(1,img_size,filename,'pdf',margins) % 1 is the figure handle
%     % Landscape
%     filename='peaks_land';
%     img_size=[9 6.5]; % [width height];
%     tpscrop(img_size,filename,'pdf') % pdf landscape is simply given size
%     margins=[0 0 -.3 0]; % will crop the title from the top
%     tpscrop(img_size,filename,'eps',margins)
%
% Note: To get the correct size the eps file is saved multiple times. Some
% delay may be noticed, or a file may not be ready for viewing if still
% process. Adobe Reader will lock a file, so it must be closed prior to
% recreated a pdf file. GSView will automatically update, thus recommended
% for view .eps and .pdf files, especially to "see" printed size.
%
% written by: Lt Col Tim Jorris, TPS/CS, July 2009
%             ver 2: added 'emf' capability

[Hf,img_size,filename, fmt, margins, porient] ...
    = getinputs(varargin{:}); % User may or may not have provided one
if Hf==0, return, end % sent a display message

%%
% There are two print setting that dictate how an image will appear once
% "printed". A .eps must be printed, a .pdf can be saved.  For a .eps the
% "margins" will be set by modifying the bounding box setting directly
% within the .eps file, note the .eps file must exist first so this is a
% print, modify, print process. Alternatively, a .pdf file will modify the
% image size based on the 'PaperPosition' and the 'PaperSize'.

OldPaperProps=get(Hf,{'PaperUnits','PaperPosition',...
    'PaperSize','PaperOrientation','PaperPositionMode'});
switch fmt
    case 'eps'
%         if img_size(1) > 8.5 && strcmpi(porient,'portrait')
%             warning('Setting the ''orient'' input to ''landscape'' should provide better results')
%         end
        buffer=[3 0 0 3]/72; % too much and I got into a size oscillation with a text box
        margins=margins+buffer; % this prevent cropping too tight, 6pt is a half letter
        makeeps(Hf,img_size, margins, filename,porient)
    otherwise
        buffer=[0 0 0 0];       % couldn't find a universal formula
        margins=margins+buffer; % this can prevent clipping or eliminate white space
        makepdf(Hf,img_size, margins, filename,fmt)
%     otherwise
%         warning(['The eps, pdf, and png formats are recommended, and can support user defined ''margins''', char(10), ...
%                 'Results will likely contain lots of whitespace, i.e. not cropped'])
end

set(Hf,{'PaperUnits','PaperPosition',...
    'PaperSize','PaperOrientation','PaperPositionMode'},OldPaperProps) % just in case user set something else

function makepdf(Hf,out_size, marg, filename,fmt)
% PDF files do care about left and bottom, set to 0's and use margins
lft=0; bot=0; % arbitray location 
img_size=out_size-[marg(1)+marg(2), marg(3)+marg(4)];
paper_size=out_size;  
set(Hf, 'PaperPositionMode', 'manual')

set(Hf,'PaperOrientation','portrait')
paper_pos=[lft+marg(1), bot+marg(4), img_size];
set(Hf,'PaperUnits','inches')
set(Hf,'PaperSize',paper_size) % only ensure enough of a canvas, does effect cropping
set(Hf,'PaperPosition',paper_pos) % the left bottom is meaningless in an eps, 1 is chosen to get it out of the corner in GSView
% saveas just calls print, so use the print command
fig=sprintf('-f%d',Hf.Number);  % creates '-f1' for figure 1
if strcmpi(fmt,'emf')==1, fmt='meta'; end
switch fmt
    case 'pdf' % default works
        extra={};
    otherwise
        extra={};
        % extra={'-zbuffer','-r600'};   % bearly better than -painter
        % extra={'-painters','-r600'};
        % extra={'-opengl','-r600'}; % opengl lost 'Box' components
end
fmt=['-d',fmt];
try
    % print(fig,fmt,'-r600',filename)
    % print(fig,fmt,filename,'-opengl','-r600') % very promising for .png
    print(fig,fmt,filename,extra{:})
catch ME
    if strcmpi(ME.identifier,'MA5TLAB:Print:CannotCreateOutputFile')==0
        error('Be sure the file is not open by Adobe Reader')
    else
        rethrow(lasterror)
    end
end

function makeeps(Hf,out_size, marg, filename,porient)
%% Create eps, check bounding box, resize and impose margins
% margin is [left bottom right top]
lft=1; bot=1; % arbitray location 
img_size=out_size-[marg(1)+marg(2), marg(3)+marg(4)];
newbb=[lft,bot,lft+img_size(1)+marg(1)+marg(2),bot+img_size(2)+marg(3)+marg(4)];
paper_size=out_size;   
 set(Hf, 'PaperPositionMode', 'manual')
switch porient
    case 'portrait'
        set(Hf,'PaperOrientation','portrait')                    
        paper_pos=[lft+marg(1), bot+marg(4), img_size];        
    case 'landscape'        
        % This requires swapping the bounding box dimensions as well
        set(Hf,'PaperOrientation','landscape')
         % eps doesn't know about the rotation so the new dimensions are:
         %  user perception -> eps reality
         %  left            -> bot    % typical y-axis
         %  right           -> top    
         %  bottom          -> right  % below the x-axis
         %  top             -> left   % above the title
         %
         % user gives order as left right top bottom
        marg=marg([3,4,2,1]);
        % paper_size=[11 8.5];
        % img_size is used for bounding box calc, remains in portrait
        % landscape reference:
        %   landscape left and top (not bottom like portraint)
        %  [1 0 9 3] has a 9-inch x-axis 1-inch from left and at the top of
        %  the page. So to move the whole thing to the bottom of the page
        %  you must push it from the top (8.5 inches of paper) unit it has
        %  the bottom margin (below x-axis) desired.
        % -8.5+bot+out_size(2) force bottom margin in landscape (which is on the right)
        % paper_pos=[lft, -8.5+bot+out_size(2), img_size([2,1])]; 
        % bot, -lft force left margin in portrait
        paper_pos=[bot+marg(1), -lft+marg(4), img_size];         
        newbb=newbb([1,2,4,3]);
    otherwise
        error('Paper Orientation must be ''portrait'' or ''landscape''')
end
set(Hf,'PaperSize',paper_size) % only ensure enough of a canvas, does effect cropping
set(Hf,'PaperUnits','inches')
set(Hf,'PaperPosition',paper_pos) % the left bottom is meaningless in an eps, 1 is chosen to get it out of the corner in GSView

fig=sprintf('-f%d',Hf.Number);
fmt='-depsc2';
% fmt='-depsc';
% '-tiff','-r300' lost the tight bounding box (sts) and had no visible 
% advantage when imported to Word. Thus, will not be used.
print(fig,fmt,filename,'-painters') % without '-loose' the bounding box is tight (sts), but now the image size is wrong
% Check image size with automatic bounding box having been set
if ~strcmpi(filename(end-2:end),'eps'), filename=[filename,'.eps']; end

% Aside from margins, bb should be tight, so enlarge to fit desire (sts)

img_size2=img_size; % assume it's correct the first time
lft2=lft+marg(1); bot2=bot+marg(4);
bb=fixbb(filename); % want full name for fopen within fixbb
% All math is done here, fixbb just reads and writes
wid=abs(bb(3)-bb(1)); % bb is left, bottom, right, top
hgt=abs(bb(4)-bb(2)); % abs since they can be upper right to bottom left
% bb, wid, hgt
if strcmpi(porient,'portrait')
    errors=[lft2-bb(1), bot2-bb(2), ...
        1-img_size2(1)/wid, 1-img_size2(2)/hgt ];
else
	errors=[lft2-bb(1), bot2-bb(2), ...
        1-img_size2(1)/hgt, 1-img_size2(2)/wid ]; 
end
iter=1;
while norm(errors) > .02 && iter < 8      
    lft2=lft2 + (lft+marg(1)-bb(1)); % cropping may move initial position
    bot2=bot2 + (bot+marg(4)-bb(2));
    switch porient
    case 'portrait'
        img_size2=[img_size(1)*img_size2(1)/wid, ...
                   img_size(2)*img_size2(2)/hgt];
        paper_pos=[lft2 bot2 img_size2];        
    case 'landscape'
        img_size2=[img_size(1)*img_size2(1)/hgt, ...
            img_size(2)*img_size2(2)/wid];
        paper_pos=[bot2, -lft2, img_size2];  % old left, bottom, new size                 
    end   
    set(Hf,'PaperPosition',paper_pos) % the left bottom is meaningless in an eps, 1 is chosen to get it out of the corner in GSView
    % print(fig,fmt,'-r600',filename) % too big, not sure it did much
    print(fig,fmt,filename)
    bb=fixbb(filename); % want full name for fopen within fixbb
    % All math is done here, fixbb just reads and writes
    wid=abs(bb(3)-bb(1)); % bb is left, bottom, right, top
    hgt=abs(bb(4)-bb(2)); % abs since they can be upper right to bottom left
%     bb, wid, hgt
    if strcmpi(porient,'portrait')
        errors=[lft+marg(1)-bb(1), bot+marg(4)-bb(2), ...
            1-img_size(1)/wid, 1-img_size(2)/hgt ];
    else
        errors=[lft+marg(1)-bb(1), bot+marg(4)-bb(2), ...
            1-img_size(1)/hgt, 1-img_size(2)/wid ];
    end
    iter=iter+1;
end
% errors, normerror=norm(errors), iter
bb=fixbb(filename,newbb);
% bb=fixbb(filename); % just read, don't fix, debug only
% All math is done here, fixbb just reads and writes
% wid=bb(3)-bb(1); % bb is left, bottom, right, top
% hgt=bb(4)-bb(2);
% bb, wid, hgt

function [Hf,img_size,filename, fmt, margins, porient]=getinputs(varargin)
% Figure out if a valid figure handle was provide by user, or use current
img_size=[6 8]; filename=''; fmt='eps';
margins=[0 0 0 0]; porient='portrait';
if nargin==0
    disp(['Inputs are required: type ''doc ',mfilename,''' for more help.'])
    Hf=0;
elseif nargin > 0 && length(varargin{1})==1 && ishandle(varargin{1})
    Hf=varargin{1};
    varargin(1)=[]; 
elseif nargin > 0 && length(varargin{1})==1 && ~ishandle(varargin{1}) 
        error('Invalid figure handle in first argument')
else
    Hf=gcf;
end
% tpscrop(img_size,filename, fmt, margins, orient)
lenvar=length(varargin);
if lenvar < 2
    disp('''img_size'' and ''filename'' are required inputs'), Hf=0; return
else
    img_size=varargin{1};
    if img_size(1) > 8.5, porient='landscape'; end % can be overwritten next
    filename=varargin{2};
    if lenvar >= 3, fmt=varargin{3}    ; end
    if lenvar >= 4
        margins=varargin{4};
        if isempty(margins), margins=[0 0 0 0]; end
    end
    if lenvar >= 5, porient=varargin{5}; end
end

function bb=fixbb(filename,newbb)
% function bb=fixbb(filename, newbb)
%
% This function serves two roles. 
%   1. Read the default value of bb created during an eps file save
%   2. Add (or subtract) a margin from the existing bounding box
%
% eps files work entirely in points, all input and output will be inches
%
% This is all taken from:
%   
% function fixepsbbox(filename)
% 
% matlab seems to compute a bounding box on eps files which is too
% large in the x-direction
% 
% this script fixes the bounding box
% it is 99% stolen from fixeps.m, located here:
% http://www.mathworks.com/matlabcentral/fileexchange/loadFile.do?objectId=4818&objectType=file
% the only change is that this changes the bbox numbers
% seriously, the only change is the addition of lines 22,23,33,34
% 
% boundingbox has form of:
% %%BoundingBox:    x1   y1   x2   y2
% where (x1,y1) is lower-left and (x2,y2) is upper-right
% 
% matlab computes x1 too small and x2 too large
% changes lines to:
% %%BoundingBox:    x1+dx1 y1 x2+dx2 y2

% default amount to change bbox - found this fixed my plots just fine
% dx1 = 10;	% amount to move x1
% dx2 = -25;	% amount to move x2

fid = fopen(filename,'r+');
if fid == -1
    error(['Filename ''',filename,''' could not opened'])
end
k=0;
points_in_inch=72; 
tline='';
while k < 2  && ~isnumeric(tline)   % 2 locations to replace.
    tline = fgetl(fid);                                     % get one line text
    stridx=strfind(tline,'Box:');
	if isempty(stridx)==0
        len=length(tline);                                  % the original line length
		bb=sscanf(tline(stridx+4:end),'%i');                % read the numbers
        if nargin == 1            
            break % just want the numbers
        else
            if k==0
                newbb=round(newbb*points_in_inch); % must be integers
            end % just do once
            % The user is instructed to provide "margins" so a positive x1, y1
            % margin really requires a subtract; whereas a x2, y2 margin is add
            bb(1) = newbb(1);								% change x1
            bb(2) = newbb(2);								% change y1
            bb(3) = newbb(3);								% change x2
            bb(4) = newbb(4);								% change y2
            bbstr=sprintf('%g %g %g %g',bb);                    % write bb numbers to string
            tline=tline(1:stridx+3);                             % keep the "%%(page)boundingbox" string (with starting '%%')
            spaces(1:len-length(tline)-length(bbstr)-1)=' ';    % add trailing spaces as to overwrite old line completely
            tline=[tline ' ' bbstr spaces];                     % concate numbers and blank spaces to "%%(page)boundingbox"
            fseek(fid,-len-2,'cof');                            % before using fprintf search to correct position
            count = fprintf(fid,'%s',tline);
            fseek(fid,2,'cof');                                 % seek to beginning of line (for windows text file) on
            % for linux: change '2' to '1' I think
            k=k+1;
        end
	end
end
fclose(fid);
bb=bb/points_in_inch; 

