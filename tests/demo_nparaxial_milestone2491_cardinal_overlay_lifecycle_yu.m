function results = demo_nparaxial_milestone2491_cardinal_overlay_lifecycle_yu()
%DEMO_NPARAXIAL_MILESTONE2491_CARDINAL_OVERLAY_LIFECYCLE_YU Lifecycle checks.

    testFolder = fileparts(mfilename('fullpath'));
    rootFolder = fileparts(testFolder);
    addpath(rootFolder);
    addpath(fullfile(rootFolder, 'core'));

    overlayTag = "nparaxial_cardinal_overlay";
    numChecks = 0;

    finiteCard = nparaxial_cardinal_points_yu( ...
        nparaxial_default_prescription_yu("single thin lens"), 0, 0);
    translationCard = nparaxial_cardinal_points_yu( ...
        nparaxial_default_prescription_yu( ...
        "Homogeneous translation / free-space propagation"), 0, 100);

    fig = figure('Visible', 'off');
    cleanupFig = onCleanup(@() close(fig)); %#ok<NASGU>
    ax = axes(fig);
    hold(ax, 'on');
    yLimits = [-12, 12];
    zLimits = [-100, 100];
    ylim(ax, yLimits);
    xlim(ax, zLimits);
    plot(ax, [-20, 20], [8, 4], ...
        'Color', [0 0.4470 0.7410], 'DisplayName', 'UMR');
    plot(ax, [-20, 20], [0, 0], ...
        'Color', [0.8500 0.0000 0.0000], 'DisplayName', 'CR');
    plot(ax, [-20, 20], [-8, -4], ...
        'Color', [0.0000 0.6000 0.0000], 'DisplayName', 'LMR');

    nparaxial_plot_cardinal_points_yu(ax, finiteCard, yLimits, zLimits);
    firstCount = count_cardinal_objects_local(ax, overlayTag);
    assert(firstCount > 0, ...
        'First finite-power cardinal overlay should create tagged objects.');
    numChecks = numChecks + 1;

    nDeleted = nparaxial_clear_cardinal_points_yu(ax);
    assert(nDeleted == firstCount, ...
        'Clear helper should report the number of deleted cardinal objects.');
    assert(count_cardinal_objects_local(ax, overlayTag) == 0, ...
        'Clear helper should remove all cardinal overlay objects.');
    numChecks = numChecks + 1;

    nparaxial_plot_cardinal_points_yu(ax, finiteCard, yLimits, zLimits);
    countAfterFirstPlot = count_cardinal_objects_local(ax, overlayTag);
    nparaxial_plot_cardinal_points_yu(ax, finiteCard, yLimits, zLimits);
    countAfterSecondPlot = count_cardinal_objects_local(ax, overlayTag);
    assert(countAfterSecondPlot == countAfterFirstPlot, ...
        'Repeated cardinal plotting should not accumulate duplicate objects.');
    numChecks = numChecks + 1;

    hCardinal = findall(ax, 'Tag', char(overlayTag));
    tags = string(get(hCardinal, 'Tag'));
    handleVisibility = string(get(hCardinal, 'HandleVisibility'));
    assert(all(tags == overlayTag), ...
        'All cardinal overlay objects should have the owned overlay tag.');
    assert(all(handleVisibility == "off"), ...
        'All cardinal overlay objects should remain hidden from legends.');
    numChecks = numChecks + 1;

    lgd = legend(ax, 'show');
    legendNames = string(lgd.String(:));
    cardinalLabels = ["F"; "F'"; "H"; "H'"; "N"; "N'"];
    assert(all(~ismember(cardinalLabels, legendNames)), ...
        'Legend should not include cardinal point labels.');
    assert(all(ismember(["UMR"; "CR"; "LMR"], legendNames)), ...
        'Ray role labels should remain available to the legend.');
    numChecks = numChecks + 1;

    nparaxial_plot_cardinal_points_yu(ax, finiteCard, yLimits, zLimits);
    assert(count_cardinal_objects_local(ax, overlayTag) > 0, ...
        'Finite-power overlay should exist before afocal refresh.');
    hAfocal = nparaxial_plot_cardinal_points_yu( ...
        ax, translationCard, yLimits, zLimits);
    assert(isempty(hAfocal), ...
        'Afocal/translation cardinal plotting should return no handles.');
    assert(count_cardinal_objects_local(ax, overlayTag) == 0, ...
        'Afocal/translation refresh should leave no stale cardinal objects.');
    numChecks = numChecks + 1;

    priorResults = demo_nparaxial_milestone249_cardinal_plot_overlay_yu();
    assert(priorResults.num_checks >= 6, ...
        'Existing 2.4.9 cardinal overlay test should still pass.');
    numChecks = numChecks + 1;

    appSmoke = app_lifecycle_smoke_local(rootFolder, overlayTag);
    if appSmoke == "passed"
        numChecks = numChecks + 1;
    end

    hold(ax, 'off');

    results = struct();
    results.case_name = "milestone2491_cardinal_overlay_lifecycle";
    results.num_checks = numChecks;
    results.app_smoke = appSmoke;
    results.first_cardinal_object_count = firstCount;
end


function n = count_cardinal_objects_local(ax, overlayTag)
    n = numel(findall(ax, 'Tag', char(overlayTag)));
end


function status = app_lifecycle_smoke_local(rootFolder, overlayTag)
    status = "skipped";
    if ~usejava('awt')
        return
    end

    oldPath = path;
    cleanupPath = onCleanup(@() path(oldPath)); %#ok<NASGU>
    addpath(rootFolder);
    addpath(fullfile(rootFolder, 'core'));

    app = YU_NParaxialSurface_App_V1();
    cleanupApp = onCleanup(@() delete(app)); %#ok<NASGU>
    app.UIFigure.Visible = 'off';

    cardinal = find_checkbox_local(app.UIFigure, "Show cardinal points");
    assert(~cardinal.Value, ...
        'Show cardinal points should default OFF.');

    presetDropdown = find_dropdown_with_item_local( ...
        app.UIFigure, "Single thin lens");
    presetDropdown.Value = 'Single thin lens';
    presetButton = find_button_local(app.UIFigure, 'Load Default');
    call_callback_local(presetButton.ButtonPushedFcn, presetButton);
    drawnow limitrate

    runButton = find_button_local(app.UIFigure, 'Run Trace');
    call_callback_local(runButton.ButtonPushedFcn, runButton);
    drawnow limitrate
    rayAxes = find_ray_axes_local(app.UIFigure);
    assert(count_cardinal_objects_local(rayAxes, overlayTag) == 0, ...
        'Cardinal markers should remain hidden while the checkbox is OFF.');

    cardinal.Value = true;
    call_callback_local(cardinal.ValueChangedFcn, cardinal);
    drawnow limitrate
    enabledCount = count_cardinal_objects_local(rayAxes, overlayTag);
    assert(enabledCount > 0, ...
        'Enabling Show cardinal points should plot tagged markers.');

    cardinal.Value = false;
    call_callback_local(cardinal.ValueChangedFcn, cardinal);
    drawnow limitrate
    assert(count_cardinal_objects_local(rayAxes, overlayTag) == 0, ...
        'Disabling Show cardinal points should delete cardinal markers.');

    cardinal.Value = true;
    call_callback_local(cardinal.ValueChangedFcn, cardinal);
    drawnow limitrate
    countBeforeRerun = count_cardinal_objects_local(rayAxes, overlayTag);
    call_callback_local(runButton.ButtonPushedFcn, runButton);
    drawnow limitrate
    countAfterRerun = count_cardinal_objects_local(rayAxes, overlayTag);
    assert(countAfterRerun == countBeforeRerun, ...
        'Repeated Run Trace should refresh without duplicating markers.');

    presetDropdown.Value = 'Homogeneous translation / free-space propagation';
    call_callback_local(presetButton.ButtonPushedFcn, presetButton);
    drawnow limitrate
    assert(count_cardinal_objects_local(rayAxes, overlayTag) == 0, ...
        'Changing preset should clear stale cardinal markers.');

    call_callback_local(runButton.ButtonPushedFcn, runButton);
    drawnow limitrate
    assert(count_cardinal_objects_local(rayAxes, overlayTag) == 0, ...
        'Translation preset should not leave finite-power cardinal markers.');

    status = "passed";
end


function checkbox = find_checkbox_local(fig, textValue)
    checkboxes = findall(fig, '-isa', 'matlab.ui.control.CheckBox');
    for k = 1:numel(checkboxes)
        if string(checkboxes(k).Text) == string(textValue)
            checkbox = checkboxes(k);
            return
        end
    end
    error('Could not find checkbox "%s".', textValue);
end


function dropdown = find_dropdown_with_item_local(fig, itemText)
    dropdowns = findall(fig, '-isa', 'matlab.ui.control.DropDown');
    for k = 1:numel(dropdowns)
        if any(string(dropdowns(k).Items) == string(itemText))
            dropdown = dropdowns(k);
            return
        end
    end
    error('Could not find dropdown containing item "%s".', itemText);
end


function button = find_button_local(fig, textValue)
    buttons = findall(fig, '-isa', 'matlab.ui.control.Button', ...
        'Text', char(textValue));
    if isempty(buttons)
        error('Could not find button "%s".', textValue);
    end
    button = buttons(1);
end


function ax = find_ray_axes_local(fig)
    axesList = findall(fig, '-isa', 'matlab.ui.control.UIAxes');
    for k = 1:numel(axesList)
        titleText = string(axesList(k).Title.String);
        if contains(titleText, "N-element paraxial ray trace")
            ax = axesList(k);
            return
        end
    end
    error('Could not find the Ray Diagram axes.');
end


function call_callback_local(callbackFcn, source)
    if isempty(callbackFcn)
        error('UI callback was empty.');
    end
    if iscell(callbackFcn)
        callbackFcn{1}(source, []);
    else
        callbackFcn(source, []);
    end
end
