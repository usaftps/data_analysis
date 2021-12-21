% This function adds a TPS-style title and subtitles to a figure. 
%
% Written by Juan Jurado

function testPointTitle(bigTitle,colText)
    % Make some room for all the text
    [normCols,nLines] = normalizeColumns(colText);
    ax = gca;
    scale = 0.05*nLines;
    ax.Position(4) = ax.Position(4)*(1-scale);
    % Set the column text
    maxHeight = makeColumnText(normCols,'helvetica',16);
    % Set the big title
    makeBigTitle(bigTitle,'helvetica',20,maxHeight);
end

function [colsOut,maxLines] = normalizeColumns(colText)
    nLines = cellfun(@length, colText);
    nCols = length(colText);
    maxLines = max(nLines);
    tallCol = cell(maxLines,1);
    colsOut = cell(1,nCols);
    for ii = 1:length(colsOut)
        thisCol = tallCol;
        thisCol(1:nLines(ii)) = colText{1,ii};
        colsOut{ii} = thisCol;
    end
end

function t = makeBigTitle(bigTitle,fontName,fontSize,maxHeight)
    t = title(bigTitle);
    t.Units = 'normalized';
    t.FontName = fontName;
    t.FontSize = fontSize;
    t.VerticalAlignment = 'bottom';
    t.Position(2) = 1 + maxHeight;
end

function maxHeight = makeColumnText(strings,fontName,fontSize)
    ax = gca;
    ax.Units = 'normalized';
    nRows = length(strings);
    heights = zeros(nRows,1);
    totalWidth = 0;
    hText = gobjects(nRows,1);
    space = 0.1;
    for ii = 1:nRows
        hText(ii) = text(0,0,strings{ii});
        set(hText(ii),...
            'FontSize',fontSize,...
            'FontName',fontName,...
            'Units','normalized',...
            'Position', [totalWidth,1,0],...
            'HorizontalAlignment','left',...
            'VerticalAlignment','bottom',...
            'Tag','TestPointTitle');
        heights(ii) = hText(ii).Extent(4);
        totalWidth = totalWidth + hText(ii).Extent(3) + space;
    end
    maxHeight = max(heights);   
    centeringFactor = 0.5-(totalWidth-space)/2;
    for ii = 1:nRows
        hText(ii).Position(1) = hText(ii).Position(1) + centeringFactor;
    end
end





