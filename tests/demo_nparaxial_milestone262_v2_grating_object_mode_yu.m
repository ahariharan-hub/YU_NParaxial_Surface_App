function results = demo_nparaxial_milestone262_v2_grating_object_mode_yu()
%DEMO_NPARAXIAL_MILESTONE262_V2_GRATING_OBJECT_MODE_YU V2 grating UI checks.

    testFolder = fileparts(mfilename('fullpath'));
    rootFolder = fileparts(testFolder);
    addpath(rootFolder);
    addpath(fullfile(rootFolder, 'core'));
    addpath(fullfile(rootFolder, 'workflows'));
    addpath(fullfile(rootFolder, 'plotting'));

    numChecks = 0;
    v2File = fullfile(rootFolder, 'YU_NParaxialSurface_App_V2.m');
    sourceText = string(fileread(v2File));
    assert(contains(sourceText, 'nparaxial_make_grating_order_rays_yu'), ...
        'V2 should use the scriptable grating ray generator.');
    assert(~contains(sourceText, 'nparaxial_paraxial_validity_yu') && ...
        ~contains(sourceText, 'nparaxial_validity_field_sweep_yu'), ...
        'V2 source should not call heavy diagnostics.');
    numChecks = numChecks + 3;

    [appSmoke, appChecks, pointSeconds, gratingSeconds] = ...
        v2_grating_smoke_local(rootFolder);
    numChecks = numChecks + appChecks;

    [v1Smoke, v1Checks] = v1_smoke_local(rootFolder);
    numChecks = numChecks + v1Checks;

    results = struct();
    results.case_name = "milestone262_v2_grating_object_mode";
    results.num_checks = numChecks;
    results.app_smoke = appSmoke;
    results.v1_smoke = v1Smoke;
    results.point_run_trace_s = pointSeconds;
    results.grating_run_trace_s = gratingSeconds;
end


function [status, numChecks, pointSeconds, gratingSeconds] = ...
    v2_grating_smoke_local(rootFolder)

    status = "skipped";
    numChecks = 0;
    pointSeconds = NaN;
    gratingSeconds = NaN;
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
    assert(isvalid(app.UIFigure), 'V2 should launch.');
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
    assert(numel(tabTitles) == 5 && all(ismember(expectedTabs, tabTitles)), ...
        'V2 should remain a five-tab lightweight viewer.');
    numChecks = numChecks + 1;

    objectType = find_by_tag_local(app.UIFigure, ...
        'matlab.ui.control.DropDown', 'nparaxial_v2_object_type');
    assert(all(ismember(["Point object", "Grating object"], ...
        string(objectType.Items))), ...
        'V2 should expose Point object and Grating object source modes.');
    numChecks = numChecks + 1;

    runButton = find_by_tag_local(app.UIFigure, ...
        'matlab.ui.control.Button', 'nparaxial_v2_run_trace');
    timingLabel = find_by_tag_local(app.UIFigure, ...
        'matlab.ui.control.Label', 'nparaxial_v2_timing_label');
    rayAxes = find_by_tag_local(app.UIFigure, ...
        'matlab.ui.control.UIAxes', 'nparaxial_v2_ray_axes');

    objectType.Value = 'Point object';
    call_callback_local(objectType.ValueChangedFcn, objectType);
    call_callback_local(runButton.ButtonPushedFcn, runButton);
    drawnow limitrate
    pointSeconds = parse_run_time_local(timingLabel.Text);
    assert(isfinite(pointSeconds) && pointSeconds >= 0 && ...
        ~isempty(findall(rayAxes, 'Type', 'Line')), ...
        'Point-object mode should still run and plot.');
    assert(isempty(findall(rayAxes, ...
        'Tag', 'nparaxial_v2_grating_order_label')), ...
        'Point-object mode should not leave grating labels.');
    numChecks = numChecks + 2;

    objectType.Value = 'Grating object';
    call_callback_local(objectType.ValueChangedFcn, objectType);
    call_callback_local(runButton.ButtonPushedFcn, runButton);
    drawnow limitrate
    gratingSeconds = parse_run_time_local(timingLabel.Text);
    labels = grating_order_label_strings_local(rayAxes);
    assert(isfinite(gratingSeconds) && gratingSeconds >= 0 && ...
        all(contains(strjoin(labels, " "), ["m = -1", "m = 0", "m = +1"])), ...
        'Grating-object mode should trace and label propagating orders.');
    numChecks = numChecks + 2;

    legendLabels = legend_labels_local(app.UIFigure);
    assert(any(contains(legendLabels, "m = -1")) && ...
        any(contains(legendLabels, "m = 0")) && ...
        any(contains(legendLabels, "m = +1")), ...
        'Ray Diagram legend should expose diffraction-order entries.');
    numChecks = numChecks + 1;

    periodField = find_by_tag_local(app.UIFigure, ...
        'matlab.ui.control.NumericEditField', ...
        'nparaxial_v2_grating_period_um');
    periodField.Value = 0.2;
    call_callback_local(periodField.ValueChangedFcn, periodField);
    call_callback_local(runButton.ButtonPushedFcn, runButton);
    drawnow limitrate
    statusLabel = find_by_tag_local(app.UIFigure, ...
        'matlab.ui.control.Label', 'nparaxial_v2_status');
    labels = grating_order_label_strings_local(rayAxes);
    joinedLabels = strjoin(labels, " ");
    assert(contains(string(statusLabel.Text), "2 non-propagating") && ...
        contains(joinedLabels, "m = -1") && ...
        contains(joinedLabels, "m = 0") && ...
        contains(joinedLabels, "m = +1") && ...
        ~contains(joinedLabels, "m = -2") && ...
        ~contains(joinedLabels, "m = +2"), ...
        'Non-propagating grating orders should be reported and not traced.');
    numChecks = numChecks + 2;

    repeatedCounts = zeros(1, 3);
    for k = 1:3
        call_callback_local(runButton.ButtonPushedFcn, runButton);
        drawnow limitrate
        repeatedCounts(k) = ray_diagram_object_count_local(rayAxes);
    end
    assert(max(repeatedCounts) - min(repeatedCounts) <= 2, ...
        'Repeated grating Run Trace calls should not accumulate graphics.');
    numChecks = numChecks + 1;

    objectType.Value = 'Point object';
    call_callback_local(objectType.ValueChangedFcn, objectType);
    call_callback_local(runButton.ButtonPushedFcn, runButton);
    drawnow limitrate
    assert(isempty(findall(rayAxes, ...
        'Tag', 'nparaxial_v2_grating_order_label')), ...
        'Switching back to point mode should clear grating graphics.');
    numChecks = numChecks + 1;

    objectType.Value = 'Grating object';
    call_callback_local(objectType.ValueChangedFcn, objectType);
    periodField.Value = 4.0;
    call_callback_local(periodField.ValueChangedFcn, periodField);
    call_callback_local(runButton.ButtonPushedFcn, runButton);
    drawnow limitrate

    select_tab_local(tabGroup, "System Matrix");
    matrixText = find_by_tag_local(app.UIFigure, ...
        'matlab.ui.control.TextArea', 'nparaxial_v2_matrix_text');
    prescriptionTable = find_by_tag_local(app.UIFigure, ...
        'matlab.ui.control.Table', 'nparaxial_v2_prescription_table');
    assert(any(contains(string(matrixText.Value), ...
        "source/ray-launch condition")) && ...
        ~any(string(prescriptionTable.Data.type) == "grating"), ...
        'System Matrix tab should keep grating out of the prescription matrix.');
    numChecks = numChecks + 2;

    select_tab_local(tabGroup, "Cardinal/Gaussian");
    cardinalText = find_by_tag_local(app.UIFigure, ...
        'matlab.ui.control.TextArea', 'nparaxial_v2_cardinal_text');
    assert(any(contains(string(cardinalText.Value), ...
        "optical system only")), ...
        'Cardinal tab should note grating changes launch rays only.');
    numChecks = numChecks + 1;

    select_tab_local(tabGroup, "Equations");
    equationsText = find_by_tag_local(app.UIFigure, ...
        'matlab.ui.control.TextArea', 'nparaxial_v2_equations_text');
    assert(any(contains(string(equationsText.Value), ...
        "n_out sin(theta_m)")) && ...
        any(contains(string(equationsText.Value), ...
        "not an ABCD matrix element")), ...
        'Equations tab should include grating launch equations.');
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


function labels = grating_order_label_strings_local(ax)
    hText = findall(ax, ...
        'Tag', 'nparaxial_v2_grating_order_label', ...
        'Type', 'Text');
    labels = strings(numel(hText), 1);
    for k = 1:numel(hText)
        labels(k) = string(hText(k).String);
    end
end


function labels = legend_labels_local(fig)
    legends = findall(fig, 'Type', 'Legend');
    labels = strings(0, 1);
    if isempty(legends)
        return
    end
    labels = string(legends(1).String);
    labels = labels(:);
    labels = labels(labels ~= "");
end


function nObjects = ray_diagram_object_count_local(ax)
    h = allchild(ax);
    h = h(isgraphics(h));
    nObjects = numel(h);
end
