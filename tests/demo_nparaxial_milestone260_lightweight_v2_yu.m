function results = demo_nparaxial_milestone260_lightweight_v2_yu()
%DEMO_NPARAXIAL_MILESTONE260_LIGHTWEIGHT_V2_YU V2 system viewer checks.

    testFolder = fileparts(mfilename('fullpath'));
    rootFolder = fileparts(testFolder);
    addpath(rootFolder);
    addpath(fullfile(rootFolder, 'core'));
    addpath(fullfile(rootFolder, 'workflows'));
    addpath(fullfile(rootFolder, 'plotting'));
    addpath(fullfile(rootFolder, 'examples'));

    numChecks = 0;
    v2File = fullfile(rootFolder, 'YU_NParaxialSurface_App_V2.m');
    assert(isfile(v2File) && exist('YU_NParaxialSurface_App_V2', 'class') == 8, ...
        'V2 app file should exist and be callable.');
    numChecks = numChecks + 1;

    sourceText = string(fileread(v2File));
    assert(~contains(sourceText, 'nparaxial_paraxial_validity_yu') && ...
        ~contains(sourceText, 'nparaxial_validity_field_sweep_yu') && ...
        ~contains(sourceText, 'nparaxial_run_validity_workflow_yu') && ...
        ~contains(sourceText, 'nparaxial_run_field_sweep_workflow_yu'), ...
        'V2 source should not call heavy validity or field-sweep helpers.');
    numChecks = numChecks + 2;

    launchExample = fullfile(rootFolder, 'examples', ...
        'demo_launch_v2_lightweight_system_viewer_yu.m');
    assert(isfile(launchExample), ...
        'V2 launch example should exist.');
    numChecks = numChecks + 1;

    [appSmoke, appChecks, runTraceSeconds] = v2_app_smoke_local(rootFolder);
    numChecks = numChecks + appChecks;

    [v1Smoke, v1Checks] = v1_smoke_local(rootFolder);
    numChecks = numChecks + v1Checks;

    results = struct();
    results.case_name = "milestone260_lightweight_v2";
    results.num_checks = numChecks;
    results.app_smoke = appSmoke;
    results.v1_smoke = v1Smoke;
    results.v2_run_trace_s = runTraceSeconds;
end


function [status, numChecks, runTraceSeconds] = v2_app_smoke_local(rootFolder)
    status = "skipped";
    numChecks = 0;
    runTraceSeconds = NaN;
    if ~usejava('awt')
        return
    end

    oldPath = path;
    cleanupPath = onCleanup(@() path(oldPath)); %#ok<NASGU>
    addpath(rootFolder);
    addpath(fullfile(rootFolder, 'core'));
    addpath(fullfile(rootFolder, 'workflows'));
    addpath(fullfile(rootFolder, 'plotting'));

    app = YU_NParaxialSurface_App_V2();
    cleanupApp = onCleanup(@() delete(app)); %#ok<NASGU>
    app.UIFigure.Visible = 'off';
    assert(isvalid(app.UIFigure), 'V2 should instantiate without error.');
    numChecks = numChecks + 1;

    tabGroup = find_by_tag_local(app.UIFigure, ...
        'matlab.ui.container.TabGroup', 'nparaxial_v2_tab_group');
    tabTitles = string({tabGroup.Children.Title}).';
    expectedTabs = [
        "Ray Diagram"
        "System Matrix"
        "Cardinal/Gaussian"
        "Stop/Pupils"
        "Equations"
        ];
    assert(numel(tabTitles) == numel(expectedTabs) && ...
        all(ismember(expectedTabs, tabTitles)), ...
        'V2 should expose exactly the intended lightweight tabs.');
    assert(~any(contains(tabTitles, ["Validity", "Field Sweep", ...
        "Vignetting", "Performance", "Invariant"])), ...
        'V2 should not expose heavy diagnostic tabs.');
    numChecks = numChecks + 3;

    mainGrid = find_by_tag_local(app.UIFigure, ...
        'matlab.ui.container.GridLayout', 'nparaxial_v2_main_grid');
    leftGrid = find_by_tag_local(app.UIFigure, ...
        'matlab.ui.container.GridLayout', 'nparaxial_v2_left_grid');
    tracePanel = find_by_tag_local(app.UIFigure, ...
        'matlab.ui.container.Panel', 'nparaxial_v2_trace_controls_panel');
    rayControlsPanel = find_by_tag_local(app.UIFigure, ...
        'matlab.ui.container.Panel', ...
        'nparaxial_v2_ray_fan_prescription_panel');
    resetButton = find_by_tag_local(app.UIFigure, ...
        'matlab.ui.control.Button', 'nparaxial_v2_reset_defaults');
    prescriptionTable = find_by_tag_local(app.UIFigure, ...
        'matlab.ui.control.Table', 'nparaxial_v2_prescription_table');
    addThinLensButton = findall(app.UIFigure, ...
        '-isa', 'matlab.ui.control.Button', 'Text', 'Add Thin Lens');
    assert(numel(mainGrid.ColumnWidth) == 2 && ...
        numel(leftGrid.RowHeight) == 2 && ...
        string(tracePanel.Title) == "Trace Controls" && ...
        string(rayControlsPanel.Title) == "Ray Fan / Prescription Controls" && ...
        string(resetButton.Text) == "Reset Defaults" && ...
        istable(prescriptionTable.Data) && ~isempty(addThinLensButton), ...
        'V2 should retain the V1-style shell, controls, and prescription editor.');
    numChecks = numChecks + 1;

    runButton = find_by_tag_local(app.UIFigure, ...
        'matlab.ui.control.Button', 'nparaxial_v2_run_trace');
    call_callback_local(runButton.ButtonPushedFcn, runButton);
    drawnow limitrate
    timingLabel = find_by_tag_local(app.UIFigure, ...
        'matlab.ui.control.Label', 'nparaxial_v2_timing_label');
    runTraceSeconds = parse_run_time_local(timingLabel.Text);
    assert(isfinite(runTraceSeconds) && runTraceSeconds >= 0, ...
        'V2 default Run Trace should complete and report timing.');
    numChecks = numChecks + 1;

    rayAxes = find_by_tag_local(app.UIFigure, ...
        'matlab.ui.control.UIAxes', 'nparaxial_v2_ray_axes');
    rayLines = findall(rayAxes, 'Type', 'Line');
    assert(~isempty(rayLines), ...
        'V2 Run Trace should update the ray diagram state.');
    numChecks = numChecks + 1;

    initialGraphicsCount = ray_diagram_object_count_local(rayAxes);
    assert(initialGraphicsCount > 0, ...
        'V2 Ray Diagram should contain graphics objects after Run Trace.');
    numChecks = numChecks + 1;

    T = prescriptionTable.Data;
    T.element_id(1) = "STALE_V2_LABEL";
    prescriptionTable.Data = T;
    call_callback_local(runButton.ButtonPushedFcn, runButton);
    drawnow limitrate
    assert(any(contains(ray_text_strings_local(rayAxes), "STALE_V2_LABEL")), ...
        'V2 test setup should place a detectable element label on the plot.');
    numChecks = numChecks + 1;

    presetDropdown = find_by_tag_local(app.UIFigure, ...
        'matlab.ui.control.DropDown', 'nparaxial_v2_preset');
    loadDefaultButton = find_by_tag_local(app.UIFigure, ...
        'matlab.ui.control.Button', 'nparaxial_v2_load_default');
    presetDropdown.Value = 'Homogeneous translation / free-space propagation';
    call_callback_local(loadDefaultButton.ButtonPushedFcn, loadDefaultButton);
    call_callback_local(runButton.ButtonPushedFcn, runButton);
    drawnow limitrate
    assert(~any(contains(ray_text_strings_local(rayAxes), "STALE_V2_LABEL")), ...
        'V2 Ray Diagram redraw should remove stale text from prior runs.');
    numChecks = numChecks + 1;

    repeatedCounts = zeros(1, 3);
    for k = 1:3
        call_callback_local(runButton.ButtonPushedFcn, runButton);
        drawnow limitrate
        repeatedCounts(k) = ray_diagram_object_count_local(rayAxes);
    end
    assert(max(repeatedCounts) - min(repeatedCounts) <= 2 && ...
        repeatedCounts(end) <= repeatedCounts(1) + 2, ...
        'Repeated identical V2 Run Trace calls should not accumulate graphics.');
    numChecks = numChecks + 1;

    presetDropdown.Value = 'Two thin lenses';
    call_callback_local(loadDefaultButton.ButtonPushedFcn, loadDefaultButton);
    call_callback_local(runButton.ButtonPushedFcn, runButton);
    drawnow limitrate
    cardinalCheck = find_by_tag_local(app.UIFigure, ...
        'matlab.ui.control.CheckBox', 'nparaxial_v2_show_cardinal_markers');
    cardinalCheck.Value = true;
    call_callback_local(cardinalCheck.ValueChangedFcn, cardinalCheck);
    drawnow limitrate
    cardinalCount1 = numel(findall(rayAxes, ...
        'Tag', 'nparaxial_cardinal_overlay'));
    call_callback_local(cardinalCheck.ValueChangedFcn, cardinalCheck);
    drawnow limitrate
    cardinalCount2 = numel(findall(rayAxes, ...
        'Tag', 'nparaxial_cardinal_overlay'));
    assert(cardinalCount1 > 0 && cardinalCount2 == cardinalCount1, ...
        'V2 cardinal overlay should appear without duplicate accumulation.');
    cardinalCheck.Value = false;
    call_callback_local(cardinalCheck.ValueChangedFcn, cardinalCheck);
    drawnow limitrate
    assert(isempty(findall(rayAxes, 'Tag', 'nparaxial_cardinal_overlay')), ...
        'V2 cardinal overlay should disappear when disabled.');
    numChecks = numChecks + 2;

    presetDropdown.Value = 'Stop clipping demo';
    call_callback_local(loadDefaultButton.ButtonPushedFcn, loadDefaultButton);
    stopPupilCheck = find_by_tag_local(app.UIFigure, ...
        'matlab.ui.control.CheckBox', 'nparaxial_v2_show_stop_pupil_markers');
    stopPupilCheck.Value = true;
    call_callback_local(runButton.ButtonPushedFcn, runButton);
    drawnow limitrate
    stopCount1 = stop_pupil_overlay_text_count_local(rayAxes);
    call_callback_local(stopPupilCheck.ValueChangedFcn, stopPupilCheck);
    drawnow limitrate
    stopCount2 = stop_pupil_overlay_text_count_local(rayAxes);
    assert(stopCount1 > 0 && stopCount2 == stopCount1, ...
        'V2 stop/pupil overlay should appear without duplicate accumulation.');
    stopPupilCheck.Value = false;
    call_callback_local(stopPupilCheck.ValueChangedFcn, stopPupilCheck);
    drawnow limitrate
    assert(stop_pupil_overlay_text_count_local(rayAxes) == 0, ...
        'V2 stop/pupil overlay should disappear when disabled.');
    numChecks = numChecks + 2;

    legendCheck = find_by_tag_local(app.UIFigure, ...
        'matlab.ui.control.CheckBox', 'nparaxial_v2_show_legend');
    legendCheck.Value = true;
    call_callback_local(legendCheck.ValueChangedFcn, legendCheck);
    call_callback_local(runButton.ButtonPushedFcn, runButton);
    drawnow limitrate
    legendLabels = legend_labels_local(app.UIFigure);
    assert(numel(legendLabels) == numel(unique(legendLabels)), ...
        'V2 legend entries should remain de-duplicated after redraws.');
    numChecks = numChecks + 1;

    focalCheck = find_by_tag_local(app.UIFigure, ...
        'matlab.ui.control.CheckBox', ...
        'nparaxial_v2_show_system_focal_length');
    fitFocalCheck = find_by_tag_local(app.UIFigure, ...
        'matlab.ui.control.CheckBox', 'nparaxial_v2_fit_focal_length');

    presetDropdown.Value = 'Single thin lens';
    call_callback_local(loadDefaultButton.ButtonPushedFcn, loadDefaultButton);
    focalCheck.Value = true;
    fitFocalCheck.Value = false;
    call_callback_local(runButton.ButtonPushedFcn, runButton);
    drawnow limitrate
    focalCount1 = numel(findall(rayAxes, ...
        'Tag', 'nparaxial_v2_focal_length_overlay'));
    focalText1 = focal_overlay_strings_local(rayAxes);
    focalTextJoined1 = strjoin(focalText1, newline);
    assert(focalCount1 > 0 && contains(focalTextJoined1, "EFL") && ...
        contains(focalTextJoined1, "f"), ...
        'V2 should draw a system focal-length overlay with EFL text.');
    numChecks = numChecks + 2;

    focalCounts = zeros(1, 3);
    for k = 1:3
        call_callback_local(runButton.ButtonPushedFcn, runButton);
        drawnow limitrate
        focalCounts(k) = numel(findall(rayAxes, ...
            'Tag', 'nparaxial_v2_focal_length_overlay'));
    end
    assert(max(focalCounts) == min(focalCounts), ...
        'Repeated V2 Run Trace calls should not accumulate focal overlays.');
    numChecks = numChecks + 1;

    presetDropdown.Value = 'Two thin lenses';
    call_callback_local(loadDefaultButton.ButtonPushedFcn, loadDefaultButton);
    focalCheck.Value = true;
    fitFocalCheck.Value = false;
    call_callback_local(runButton.ButtonPushedFcn, runButton);
    drawnow limitrate
    focalText2 = focal_overlay_strings_local(rayAxes);
    assert(any(contains(focalText2, "outside current view")), ...
        'V2 should state when H''/F'' are outside the current view.');
    numChecks = numChecks + 1;

    fitFocalCheck.Value = true;
    call_callback_local(fitFocalCheck.ValueChangedFcn, fitFocalCheck);
    drawnow limitrate
    cardForFit = nparaxial_cardinal_points_yu( ...
        table_to_prescription_yu(prescriptionTable.Data), ...
        find_by_tag_local(app.UIFigure, ...
        'matlab.ui.control.NumericEditField', ...
        'nparaxial_v2_object_z').Value, ...
        max(prescriptionTable.Data.z), 1e-12);
    xLimitsFit = xlim(rayAxes);
    assert(cardForFit.z_H2 >= xLimitsFit(1) && ...
        cardForFit.z_H2 <= xLimitsFit(2) && ...
        cardForFit.z_Fp >= xLimitsFit(1) && ...
        cardForFit.z_Fp <= xLimitsFit(2), ...
        'V2 fit focal view should include H'' and F''.');
    numChecks = numChecks + 1;

    focalCheck.Value = false;
    call_callback_local(focalCheck.ValueChangedFcn, focalCheck);
    drawnow limitrate
    assert(isempty(findall(rayAxes, ...
        'Tag', 'nparaxial_v2_focal_length_overlay')), ...
        'V2 focal-length overlay should disappear when disabled.');
    numChecks = numChecks + 1;

    cardinalCheck.Value = true;
    focalCheck.Value = true;
    fitFocalCheck.Value = false;
    call_callback_local(cardinalCheck.ValueChangedFcn, cardinalCheck);
    call_callback_local(focalCheck.ValueChangedFcn, focalCheck);
    drawnow limitrate
    cardinalWithFocal = numel(findall(rayAxes, ...
        'Tag', 'nparaxial_cardinal_overlay'));
    focalWithCardinal = numel(findall(rayAxes, ...
        'Tag', 'nparaxial_v2_focal_length_overlay'));
    call_callback_local(focalCheck.ValueChangedFcn, focalCheck);
    drawnow limitrate
    assert(cardinalWithFocal > 0 && focalWithCardinal > 0 && ...
        numel(findall(rayAxes, ...
        'Tag', 'nparaxial_v2_focal_length_overlay')) == focalWithCardinal, ...
        'V2 cardinal and focal overlays should toggle independently.');
    numChecks = numChecks + 1;

    cardinalCheck.Value = false;
    focalCheck.Value = false;
    fitFocalCheck.Value = false;
    call_callback_local(cardinalCheck.ValueChangedFcn, cardinalCheck);
    call_callback_local(focalCheck.ValueChangedFcn, focalCheck);
    drawnow limitrate

    presetDropdown.Value = 'Two thin lenses';
    call_callback_local(loadDefaultButton.ButtonPushedFcn, loadDefaultButton);
    call_callback_local(runButton.ButtonPushedFcn, runButton);
    drawnow limitrate

    select_tab_local(tabGroup, "System Matrix");
    matrixTable = find_by_tag_local(app.UIFigure, ...
        'matlab.ui.control.Table', 'nparaxial_v2_matrix_chain_table');
    matrixText = find_by_tag_local(app.UIFigure, ...
        'matlab.ui.control.TextArea', 'nparaxial_v2_matrix_text');
    assert(istable(matrixTable.Data) && ~isempty(matrixTable.Data) && ...
        any(contains(string(matrixText.Value), "Image classification")), ...
        'V2 Run Trace should compute system matrix and image classification.');
    numChecks = numChecks + 2;

    select_tab_local(tabGroup, "Cardinal/Gaussian");
    cardinalTable = find_by_tag_local(app.UIFigure, ...
        'matlab.ui.control.Table', 'nparaxial_v2_cardinal_table');
    cardinalText = find_by_tag_local(app.UIFigure, ...
        'matlab.ui.control.TextArea', 'nparaxial_v2_cardinal_text');
    assert(istable(cardinalTable.Data) && ~isempty(cardinalTable.Data) && ...
        any(contains(string(cardinalText.Value), "Cardinal / Gaussian")) && ...
        any(contains(string(cardinalText.Value), "f'_eff")) && ...
        any(contains(string(cardinalText.Value), "inside current Ray Diagram")), ...
        'V2 Run Trace should compute cardinal/Gaussian summary.');
    numChecks = numChecks + 1;

    select_tab_local(tabGroup, "Stop/Pupils");
    stopText = find_by_tag_local(app.UIFigure, ...
        'matlab.ui.control.TextArea', 'nparaxial_v2_stop_pupil_text');
    assert(any(contains(string(stopText.Value), ...
        ["No finite aperture stop", "Aperture stop"])), ...
        'V2 should report stop/pupil status or clear not-available text.');
    numChecks = numChecks + 1;

    select_tab_local(tabGroup, "Equations");
    equationsText = find_by_tag_local(app.UIFigure, ...
        'matlab.ui.control.TextArea', 'nparaxial_v2_equations_text');
    assert(any(contains(string(equationsText.Value), 'r = [y; u]')) && ...
        any(contains(string(equationsText.Value), 'script workflows')), ...
        'V2 Equations tab should include static first-order references.');
    numChecks = numChecks + 1;

    status = "passed";
end


function [status, numChecks] = v1_smoke_local(rootFolder)
    status = "skipped";
    numChecks = 0;
    if ~usejava('awt')
        return
    end

    oldPath = path;
    cleanupPath = onCleanup(@() path(oldPath)); %#ok<NASGU>
    addpath(rootFolder);
    addpath(fullfile(rootFolder, 'core'));
    addpath(fullfile(rootFolder, 'workflows'));
    addpath(fullfile(rootFolder, 'plotting'));

    app = YU_NParaxialSurface_App_V1();
    cleanupApp = onCleanup(@() delete(app)); %#ok<NASGU>
    app.UIFigure.Visible = 'off';
    runButton = findall(app.UIFigure, ...
        '-isa', 'matlab.ui.control.Button', 'Text', 'Run Trace');
    assert(~isempty(runButton), 'V1 should still launch with Run Trace.');
    call_callback_local(runButton(1).ButtonPushedFcn, runButton(1));
    drawnow limitrate
    assert(isvalid(app.UIFigure), 'V1 smoke trace should leave the app valid.');
    status = "passed";
    numChecks = 1;
end


function select_tab_local(tabGroup, titleText)
    tabs = tabGroup.Children;
    titles = string({tabs.Title});
    idx = find(titles == string(titleText), 1);
    if isempty(idx)
        error('Could not find tab "%s".', titleText);
    end
    tabGroup.SelectedTab = tabs(idx);
    if ~isempty(tabGroup.SelectionChangedFcn)
        call_callback_local(tabGroup.SelectionChangedFcn, tabGroup);
    end
    drawnow limitrate
end


function seconds = parse_run_time_local(textValue)
    token = regexp(char(textValue), '([0-9.]+)\s*s', 'tokens', 'once');
    if isempty(token)
        seconds = NaN;
    else
        seconds = str2double(token{1});
    end
end


function obj = find_by_tag_local(fig, className, tagValue)
    matches = findall(fig, '-isa', className, 'Tag', tagValue);
    if isempty(matches)
        error('Could not find %s tagged "%s".', className, tagValue);
    end
    obj = matches(1);
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


function nObjects = ray_diagram_object_count_local(ax)
    h = allchild(ax);
    h = h(isgraphics(h));
    nObjects = numel(h);
end


function textStrings = ray_text_strings_local(ax)
    hText = findall(ax, 'Type', 'Text');
    textStrings = strings(0, 1);
    for k = 1:numel(hText)
        textStrings(end+1, 1) = text_value_to_string_local( ...
            hText(k).String); %#ok<AGROW>
    end
end


function nText = stop_pupil_overlay_text_count_local(ax)
    labels = strip(ray_text_strings_local(ax));
    nText = sum(labels == "stop" | labels == "EP" | labels == "XP");
end


function labels = legend_labels_local(fig)
    legends = findall(fig, 'Type', 'Legend');
    labels = strings(0, 1);
    if isempty(legends)
        return
    end
    raw = string(legends(1).String);
    labels = raw(:);
    labels = labels(labels ~= "");
end


function textStrings = focal_overlay_strings_local(ax)
    hText = findall(ax, ...
        'Tag', 'nparaxial_v2_focal_length_overlay', ...
        'Type', 'Text');
    textStrings = strings(0, 1);
    for k = 1:numel(hText)
        textStrings(end+1, 1) = text_value_to_string_local( ...
            hText(k).String); %#ok<AGROW>
    end
end


function out = text_value_to_string_local(value)
    if iscell(value)
        out = strjoin(string(value(:)), newline);
    else
        value = string(value);
        out = strjoin(value(:), newline);
    end
end
