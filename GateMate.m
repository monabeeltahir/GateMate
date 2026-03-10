function GateMate()
% HistogramComparisonApp (1D Histogram Gating for 2 Files)
% - Fullscreen layout
% - Top Row: F1 Density, F2 Density, Overlay Density, Statistics Bar Chart
% - Bottom Row: F1 Bar Histogram, F2 Bar Histogram, Overlay Bar Histogram
% - X-Axis Limited to 10^0 to 10^6
% - X-Label: DHR (nm), Y-Label: Count

    %% Figure Setup (Fullscreen)
    screenSize = get(0, 'ScreenSize');
    figWidth  = screenSize(3); % Full screen width
    figHeight = screenSize(4); % Full screen height
    figX = 1;
    figY = 1;
    
    fig = uifigure('Name', '1D Histogram Gating Analyzer', ...
                   'Position', [figX, figY, figWidth, figHeight]);

    %% Global Visual Settings (CHANGE THESE TO ADJUST LOOK)
    % Text & Font Sizes
    axFontSize    = 14; % Font size for X and Y axis ticks
    lblFontSize   = 16; % Font size for X and Y labels
    titleFontSize = 14; % Font size for plot titles
    textFontSize  = 16; % Font size for the inside/outside % text on the plots
    
    % Axis Labels
    xAxisLabelText = 'DHR Intensity'; % Standardized X-axis label
    
    % Plot Colors (Use standard strings: 'red', 'blue', 'green', 'magenta', 'cyan', 'k')
    color1 = [0.2 0.6 0.95]; % Color for File 1 (Currently Light Blue)
    color2 = [0.9 0.3 0.3];  % Color for File 2 (Currently Red)
    color3 = [0.2 0.6 0.95]; % File 1 Histogram
    color4 = [0.9 0.3 0.3]; % File 2 Histogram
    % Bar Histogram Appearance
    numBins       = 512;    % Number of bins (bars) for the histograms
    histFaceAlpha = 0.5;    % Transparency of bars (0 = invisible, 1 = solid)
    histEdgeColor = 'none'; % Edge color of bars ('k' for black, 'none' for no borders)
    histLineWidth = 0.5;    % Thickness of the bar borders (if EdgeColor is not 'none')

    %% Layout Constants
    spacing = 15;
    controlW = 200;
    plotAreaX = controlW + 2*spacing;
    plotAreaW = figWidth - plotAreaX - spacing;
    plotAreaH = figHeight - 2*spacing;
    
    % Axes dimensions for 2x4 grid
    axW = (plotAreaW - 3*spacing) / 4;
    axH = (plotAreaH - spacing - 40) / 2;

    %% Data & State
    data1 = [];
    data2 = [];
    colNames = string.empty(0,1);
    
    % Array to hold MULTIPLE ROIs
    rois = []; 

    %% UI Controls (Left Panel)
    yPos = figHeight - spacing - 30;
    
    % File 1 Loader
    uibutton(fig, 'push', 'Text', 'Load File 1', ...
        'Position', [spacing, yPos, controlW, 30], ...
        'ButtonPushedFcn', @(~,~) loadFile(1));
    lblFile1 = uilabel(fig, 'Text', 'File 1: None', ...
        'Position', [spacing, yPos - 30, controlW, 30], 'WordWrap', 'on');
    
    yPos = yPos - 80;
    
    % File 2 Loader
    uibutton(fig, 'push', 'Text', 'Load File 2', ...
        'Position', [spacing, yPos, controlW, 30], ...
        'ButtonPushedFcn', @(~,~) loadFile(2));
    lblFile2 = uilabel(fig, 'Text', 'File 2: None', ...
        'Position', [spacing, yPos - 30, controlW, 30], 'WordWrap', 'on');
    
    yPos = yPos - 80;
    
    % Variable Selection
    uilabel(fig, 'Text', 'Select Variable:', ...
        'Position', [spacing, yPos, controlW, 20]);
    varDropdown = uidropdown(fig, ...
        'Position', [spacing, yPos - 25, controlW, 30], ...
        'Items', {'(Load files first)'}, ...
        'ValueChangedFcn', @(~,~) updatePlots());
        
    yPos = yPos - 80;
    
    % Scale Selection
    uilabel(fig, 'Text', 'X-Axis Scale:', ...
        'Position', [spacing, yPos, controlW, 20]);
    scaleDropdown = uidropdown(fig, ...
        'Position', [spacing, yPos - 25, controlW, 30], ...
        'Items', {'Log', 'Linear'}, ...
        'ValueChangedFcn', @(~,~) updatePlots());

    yPos = yPos - 100;
    
    % Gating Controls
    uibutton(fig, 'push', 'Text', '1. Draw Gate (On Top Left)', ...
        'Position', [spacing, yPos, controlW, 40], ...
        'BackgroundColor', [0.85 0.95 1], ...
        'FontWeight', 'bold', ...
        'ButtonPushedFcn', @(~,~) drawGate());
        
    uibutton(fig, 'push', 'Text', '2. Apply Gate(s)', ...
        'Position', [spacing, yPos - 50, controlW, 40], ...
        'BackgroundColor', [0.85 1 0.85], ...
        'FontWeight', 'bold', ...
        'ButtonPushedFcn', @(~,~) applyGate());
        
    uibutton(fig, 'push', 'Text', 'Clear All Gates', ...
        'Position', [spacing, yPos - 100, controlW, 30], ...
        'ButtonPushedFcn', @(~,~) clearGate());
        
    % Save Plots Button
    uibutton(fig, 'push', 'Text', 'Save High-Res Plots (600 DPI)', ...
        'Position', [spacing, yPos - 150, controlW, 35], ...
        'BackgroundColor', [1 0.95 0.8], ...
        'FontWeight', 'bold', ...
        'ButtonPushedFcn', @(~,~) saveAllPlots());

    %% Axes setup (Right Panel - 2x4 Grid)
    % Row 1 (Top)
    ax1 = uiaxes('Parent', fig, 'Position', [plotAreaX, figHeight - spacing - axH, axW, axH]);
    ax2 = uiaxes('Parent', fig, 'Position', [plotAreaX + axW + spacing, figHeight - spacing - axH, axW, axH]);
    ax3 = uiaxes('Parent', fig, 'Position', [plotAreaX + 2*(axW + spacing), figHeight - spacing - axH, axW, axH]);
    ax4 = uiaxes('Parent', fig, 'Position', [plotAreaX + 3*(axW + spacing), figHeight - spacing - axH, axW, axH]);
    
    % Row 2 (Bottom)
    ax5 = uiaxes('Parent', fig, 'Position', [plotAreaX, spacing, axW, axH]);
    ax6 = uiaxes('Parent', fig, 'Position', [plotAreaX + axW + spacing, spacing, axW, axH]);
    ax7 = uiaxes('Parent', fig, 'Position', [plotAreaX + 2*(axW + spacing), spacing, axW, axH]);
    
    % Apply Font Sizes globally
    set([ax1, ax2, ax3, ax4, ax5, ax6, ax7], 'FontSize', axFontSize);
    
    resetTitlesAndLabels();

    %% Nested Functions
    
    function resetTitlesAndLabels()
        title(ax1, 'F1 Density (Draw Gate Here)', 'FontSize', titleFontSize); grid(ax1, 'on');
        title(ax2, 'F2 Density', 'FontSize', titleFontSize); grid(ax2, 'on');
        title(ax3, 'Density Overlay (F1 & F2)', 'FontSize', titleFontSize); grid(ax3, 'on');
        title(ax4, 'Gate Statistics (%)', 'FontSize', titleFontSize); grid(ax4, 'on');
        
        title(ax5, 'F1 Histogram', 'FontSize', titleFontSize); grid(ax5, 'on');
        title(ax6, 'F2 Histogram', 'FontSize', titleFontSize); grid(ax6, 'on');
        title(ax7, 'Histogram Overlay (F1 & F2)', 'FontSize', titleFontSize); grid(ax7, 'on');
        
        % Ensure bold X and standard Y labels with DHR (nm)
        for ax = [ax1, ax2, ax3, ax5, ax6, ax7]
            xlabel(ax, xAxisLabelText, 'FontSize', lblFontSize, 'FontWeight', 'bold'); 
            ylabel(ax, 'Count', 'FontSize', lblFontSize);
        end
    end

    function loadFile(fileNum)
        [file, path] = uigetfile('*.fcs');
        if isequal(file, 0); return; end
        fullFilePath = fullfile(path, file);
        
        [~, fcshdr, ~, fcsdatcomp] = fca_readfcs(fullFilePath);
        
        if fileNum == 1
            data1 = fcsdatcomp;
            lblFile1.Text = ['File 1: ', file];
            colNames = string({fcshdr.par.name});
            varDropdown.Items = cellstr(colNames);
        else
            data2 = fcsdatcomp;
            lblFile2.Text = ['File 2: ', file];
            if isempty(data1)
                colNames = string({fcshdr.par.name});
                varDropdown.Items = cellstr(colNames);
            end
        end
        updatePlots();
    end

    function updatePlots()
        if varDropdown.Value == "(Load files first)", return; end
        
        varName = string(varDropdown.Value);
        colIdx = find(colNames == varName, 1);
        if isempty(colIdx), return; end
        
        clearGate(); 
        
        cla(ax1); cla(ax2); cla(ax3); cla(ax4); cla(ax5); cla(ax6); cla(ax7);
        resetTitlesAndLabels();
        legend(ax1, 'off'); legend(ax2, 'off'); legend(ax3, 'off'); 
        legend(ax5, 'off'); legend(ax6, 'off'); legend(ax7, 'off');
        
        isLog = strcmp(scaleDropdown.Value, 'Log');
        
        % Plot File 1
        if ~isempty(data1)
            vec1 = data1(:, colIdx);
            plotDensityLine(ax1, vec1, color1, 'File 1', isLog);
            hold(ax3, 'on'); plotDensityLine(ax3, vec1, color1, 'File 1', isLog); hold(ax3, 'off');
            
            plotStandardHistogram(ax5, vec1, color3, 'File 1', isLog);
            hold(ax7, 'on'); plotStandardHistogram(ax7, vec1, color3, 'File 1', isLog); hold(ax7, 'off');
        end
        
        % Plot File 2
        if ~isempty(data2)
            vec2 = data2(:, colIdx);
            plotDensityLine(ax2, vec2, color2, 'File 2', isLog);
            hold(ax3, 'on'); plotDensityLine(ax3, vec2, color2, 'File 2', isLog); hold(ax3, 'off');
            
            plotStandardHistogram(ax6, vec2, color4, 'File 2', isLog);
            hold(ax7, 'on'); plotStandardHistogram(ax7, vec2, color4, 'File 2', isLog); hold(ax7, 'off');
        end
    end

    function plotDensityLine(ax, vec, colorStr, nameStr, useLog)
        if useLog
            vec = vec(vec > 0); 
            if isempty(vec), return; end
            logVec = log10(vec);
            [f, xi] = ksdensity(logVec);
            xVals = 10.^xi;
            ax.XScale = 'log';
        else
            if isempty(vec), return; end
            [f, xVals] = ksdensity(vec);
            ax.XScale = 'linear';
        end
        
        yVals = f * numel(vec); 
        plot(ax, xVals, yVals, 'Color', colorStr, 'LineWidth', 2, 'DisplayName', nameStr);
        
        xlabel(ax, xAxisLabelText, 'FontSize', lblFontSize, 'FontWeight', 'bold');
        ylabel(ax, 'Count', 'FontSize', lblFontSize, 'FontWeight', 'bold');
        
        % X-Axis Limits clamped at 10^0 to 10^6
        if useLog
            xlim(ax, [1 1e6]);
        else
            xlim(ax, [0 1e6]);
        end
    end

    function plotStandardHistogram(ax, vec, colorStr, nameStr, useLog)
        % Removes zeros/negatives for log scale computation
        if useLog
            vec = vec(vec > 0);
            % Use the global numBins variable
            edges = logspace(0, 6, numBins); 
        else
            % Use the global numBins variable
            edges = linspace(0, 1e6, numBins);
        end
        
        if isempty(vec), return; end
        
        % Plot with new global visual settings
        histogram(ax, vec, 'BinEdges', edges, 'FaceColor', colorStr, ...
            'EdgeColor', histEdgeColor, 'LineWidth', histLineWidth, ...
            'FaceAlpha', histFaceAlpha, 'DisplayName', nameStr);
        
        xlabel(ax, xAxisLabelText, 'FontSize', lblFontSize, 'FontWeight', 'bold');
        ylabel(ax, 'Count', 'FontSize', lblFontSize, 'FontWeight', 'bold');
        
        if useLog
            ax.XScale = 'log';
            xlim(ax, [1 1e6]);
        else
            ax.XScale = 'linear';
            xlim(ax, [0 1e6]);
        end
    end

    function drawGate()
        if isempty(data1)
            uialert(fig, 'Please load File 1 first to draw a gate.', 'No Data'); return;
        end
        newRoi = drawrectangle(ax1, 'Color', [0.4 0.4 0.4]);
        rois = [rois, newRoi];
    end

    function applyGate()
        rois = rois(isgraphics(rois));
        
        if isempty(rois)
            uialert(fig, 'Please draw at least one gate on Top-Left File 1 first.', 'No Gate Found'); return;
        end
        
        colIdx = find(colNames == string(varDropdown.Value), 1);
        
        % Clear old visual objects
        delete(findall([ax1, ax2, ax5, ax6], 'Type', 'Text', 'Tag', 'StatBox'));
        delete(findall([ax1, ax2, ax3, ax5, ax6, ax7], 'Type', 'ConstantLine')); 
        
        %% Calculate Data (File 1)
        pctIn1 = 0; pctOut1 = 0;
        if ~isempty(data1)
            vec1 = data1(:, colIdx);
            inMask1 = false(size(vec1)); 
            
            for k = 1:numel(rois)
                pos = rois(k).Position;
                x_min = pos(1); x_max = pos(1) + pos(3);
                inMask1 = inMask1 | (vec1 >= x_min & vec1 <= x_max);
            end
            
            pctIn1 = (sum(inMask1) / numel(vec1)) * 100;
            pctOut1 = 100 - pctIn1;
            
            txt1 = sprintf('Total Inside: %.2f%%\n Total Outside: %.2f%%', pctIn1, pctOut1);
            
            % Add Stats Box to both File 1 Density and File 1 Histogram
            text(ax1, 0.02, 0.95, txt1, 'Units', 'normalized', 'VerticalAlignment', 'top', ...
                'FontSize', textFontSize, 'FontWeight', 'bold', 'BackgroundColor', 'w', 'EdgeColor', 'k', 'Tag', 'StatBox');
            text(ax5, 0.02, 0.95, txt1, 'Units', 'normalized', 'VerticalAlignment', 'top', ...
                'FontSize', textFontSize, 'FontWeight', 'bold', 'BackgroundColor', 'w', 'EdgeColor', 'k', 'Tag', 'StatBox');
        end
        
        %% Calculate Data (File 2)
        pctIn2 = 0; pctOut2 = 0;
        if ~isempty(data2)
            vec2 = data2(:, colIdx);
            inMask2 = false(size(vec2));
            
            for k = 1:numel(rois)
                pos = rois(k).Position;
                x_min = pos(1); x_max = pos(1) + pos(3);
                inMask2 = inMask2 | (vec2 >= x_min & vec2 <= x_max);
            end
            
            pctIn2 = (sum(inMask2) / numel(vec2)) * 100;
            pctOut2 = 100 - pctIn2;
            
            txt2 = sprintf('Total Inside: %.2f%%\n Total Outside: %.2f%%', pctIn2, pctOut2);
            
            % Add Stats Box to both File 2 Density and File 2 Histogram
            text(ax2, 0.02, 0.95, txt2, 'Units', 'normalized', 'VerticalAlignment', 'top', ...
                'FontSize', textFontSize, 'FontWeight', 'bold', 'BackgroundColor', 'w', 'EdgeColor', 'k', 'Tag', 'StatBox');
            text(ax6, 0.02, 0.95, txt2, 'Units', 'normalized', 'VerticalAlignment', 'top', ...
                'FontSize', textFontSize, 'FontWeight', 'bold', 'BackgroundColor', 'w', 'EdgeColor', 'k', 'Tag', 'StatBox');
        end
        
        %% Draw Vertical Gate Boundaries Across All 6 Plots
        for k = 1:numel(rois)
            pos = rois(k).Position;
            x_min = pos(1); x_max = pos(1) + pos(3);
            
            for ax = [ax1, ax2, ax3, ax5, ax6, ax7]
                xline(ax, x_min, '--k', 'LineWidth', 1.5);
                xline(ax, x_max, '--k', 'LineWidth', 1.5);
            end
        end
        
        %% Update Statistics Bar Chart
        cla(ax4);
        barData = [pctIn1, pctOut1; pctIn2, pctOut2];
        b = bar(ax4, barData, 'grouped');
        
        % Note: If you want to change the bar chart colors as well, you can do it here. 
        % I left them as Green/Grey for clarity.
        b(1).FaceColor = [0.2 0.8 0.2]; 
        b(2).FaceColor = [0.6 0.6 0.6]; 
        
        ax4.XTickLabel = {'File 1', 'File 2'};
        ylabel(ax4, 'Percentage (%)', 'FontSize', lblFontSize);
        ylim(ax4, [0 100]);
        title(ax4, 'Gate Statistics (%)', 'FontSize', titleFontSize);
        legend(ax4, {'Inside Gate(s)', 'Outside Gate(s)'}, 'Location', 'northeast', 'FontSize', axFontSize);
        grid(ax4, 'on');
    end

    function clearGate()
        rois = rois(isgraphics(rois));
        for k = 1:numel(rois)
            delete(rois(k));
        end
        rois = []; 
        
        delete(findall([ax1, ax2, ax3, ax5, ax6, ax7], 'Type', 'ConstantLine'));
        delete(findall([ax1, ax2, ax5, ax6], 'Type', 'Text', 'Tag', 'StatBox'));
        
        cla(ax4); title(ax4, 'Gate Statistics (%)', 'FontSize', titleFontSize);
    end

   function saveAllPlots()
        [baseName, path] = uiputfile({'*.png', 'PNG Image (*.png)'; '*.pdf', 'PDF File (*.pdf)'; '*.eps', 'EPS Format (*.eps)'}, 'Save Plots (Base Name)');
        if isequal(baseName, 0) || isequal(path, 0)
            return; 
        end
        
        [~, name, ext] = fileparts(baseName);
        if isempty(ext), ext = '.png'; end
        
        d = uiprogressdlg(fig, 'Title', 'Saving Publication Figures', 'Message', 'Exporting Plots...');
        
        try
            axesArray = [ax1, ax2, ax3, ax4, ax5, ax6, ax7];
            suffixArray = {'_F1_Density', '_F2_Density', '_Overlay_Density', '_Stats_BarChart', '_F1_Histogram', '_F2_Histogram', '_Overlay_Histogram'};
            
            % ---> NEW: Hide all titles before saving <---
            for i = 1:length(axesArray)
                axesArray(i).Title.Visible = 'off';
            end
            
            for i = 1:length(axesArray)
                d.Value = i / length(axesArray); 
                d.Message = sprintf('Exporting Plot %d of 7...', i);
                exportgraphics(axesArray(i), fullfile(path, [name, suffixArray{i}, ext]), 'Resolution', 600);
            end
            
            % ---> NEW: Restore all titles after saving <---
            for i = 1:length(axesArray)
                axesArray(i).Title.Visible = 'on';
            end
            
            pause(0.5); close(d);
            uialert(fig, sprintf('Successfully saved 7 high-resolution plots to:\n%s', path), 'Save Successful', 'Icon', 'success');
        catch exception
            if exist('d', 'var'), close(d); end
            
            % Safety catch: ensure titles come back even if saving fails
            if exist('axesArray', 'var')
                for i = 1:length(axesArray)
                    axesArray(i).Title.Visible = 'on';
                end
            end
            
            uialert(fig, ['Error saving plots: ' exception.message], 'Save Failed', 'Icon', 'error');
        end
    end
end