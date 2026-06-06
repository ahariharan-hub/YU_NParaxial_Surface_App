function h = nparaxial_plot_cardinal_points_yu(ax, card, yLimits, zLimits)
%NPARAXIAL_PLOT_CARDINAL_POINTS_YU Plot cardinal point diagnostics.
%
% Cardinal point markers are direct Ray Diagram annotations. They are
% deliberately hidden from legends by setting HandleVisibility to off.

    h = gobjects(0, 1);

    if nargin < 1 || isempty(ax) || ~isgraphics(ax, 'axes')
        error('A valid axes handle is required.');
    end

    wasHold = ishold(ax);
    hold(ax, 'on');
    cleanupHold = onCleanup(@() restore_hold_state_local(ax, wasHold)); %#ok<NASGU>
    nparaxial_clear_cardinal_points_yu(ax);

    if nargin < 2 || isempty(card) || ~isstruct(card)
        return
    end
    if ~isfield(card, 'is_finite_power') || ~logical(card.is_finite_power)
        return
    end

    if nargin < 3 || isempty(yLimits) || numel(yLimits) < 2 || ...
            ~all(isfinite(yLimits(1:2)))
        yLimits = ylim(ax);
    else
        yLimits = double(yLimits(1:2));
    end
    if nargin < 4 || isempty(zLimits) || numel(zLimits) < 2 || ...
            ~all(isfinite(zLimits(1:2)))
        zLimits = xlim(ax);
    else
        zLimits = double(zLimits(1:2));
    end

    yLimits = sort(yLimits);
    zLimits = sort(zLimits);
    ySpan = diff(yLimits);
    zSpan = diff(zLimits);
    if ySpan <= 0
        ySpan = max(1, abs(yLimits(1))*0.1);
        yCenter = mean(yLimits);
        yLimits = yCenter + 0.5*ySpan*[-1, 1];
    end
    if zSpan <= 0
        zSpan = max(1, abs(zLimits(1))*0.1);
    end

    zPlotLimits = zLimits + 0.10*zSpan*[-1, 1];
    fields = {'z_F', 'z_H1', 'z_N1', 'z_N2', 'z_H2', 'z_Fp'};
    labels = {'F', 'H', 'N', 'N''', 'H''', 'F'''};
    lineStyles = {':', '-.', '--', '--', '-.', ':'};
    markerColor = [0.22 0.22 0.22];
    labelColor = [0.14 0.14 0.14];
    plottedZ = zeros(0, 1);
    coincidentTol = max(1e-9, 1e-5*zSpan);

    for k = 1:numel(fields)
        if ~isfield(card, fields{k})
            continue
        end
        zValue = double(card.(fields{k}));
        if isempty(zValue) || ~isfinite(zValue(1))
            continue
        end
        zValue = zValue(1);
        if zValue < zPlotLimits(1) || zValue > zPlotLimits(2)
            continue
        end

        hLine = plot(ax, [zValue, zValue], yLimits, ...
            'LineStyle', lineStyles{k}, ...
            'Color', markerColor, ...
            'LineWidth', 0.9, ...
            'Tag', 'nparaxial_cardinal_overlay', ...
            'HandleVisibility', 'off');
        h(end+1, 1) = hLine; %#ok<AGROW>

        coincidentCount = sum(abs(plottedZ - zValue) <= coincidentTol);
        plottedZ(end+1, 1) = zValue; %#ok<AGROW>
        yOffset = (0.05 + 0.035*coincidentCount)*ySpan;
        hText = text(ax, zValue, yLimits(2) - yOffset, labels{k}, ...
            'Color', labelColor, ...
            'FontWeight', 'bold', ...
            'FontSize', 8, ...
            'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'top', ...
            'Tag', 'nparaxial_cardinal_overlay', ...
            'HandleVisibility', 'off');
        h(end+1, 1) = hText; %#ok<AGROW>
    end
end


function restore_hold_state_local(ax, wasHold)
    if isgraphics(ax, 'axes') && ~wasHold
        hold(ax, 'off');
    end
end
