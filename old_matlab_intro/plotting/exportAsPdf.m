% This function exports a Matlab figure into a publication-quality vector
% format (PDF) with minimized whitespace/margins. 
% 
% Written by Juan Jurado

function exportAsPdf(fileName)
    ax = gca;
    ax.Units = 'inches';
    ax_pos = ax.Position;
    outerpos = ax.OuterPosition;
    ti = ax.TightInset; 
    left = outerpos(1) + ti(1);
    bottom = outerpos(2) + ti(2);
    ax_width = outerpos(3) - ti(1) - ti(3);
    h = findobj('Tag','TestPointTitle');
    if ~isempty(h)
        ax_height = ax_pos(4);
    else
        ax_height = outerpos(4) - ti(4) - ti(2);
    end
    ax.Position = [left bottom ax_width ax_height];
    fig = gcf;
    fig.PaperPositionMode = 'auto';
    fig_pos = fig.PaperPosition;
    fig.PaperUnits = 'inches';
    fig.PaperSize = [fig_pos(3) fig_pos(4)];
    figColor = fig.Color;
    fig.Color = 'none';
    fig.InvertHardcopy = 'off';
    print(fig,fileName,'-dpdf')
    fig.Color = figColor;
    ax.Position = ax_pos;
end
