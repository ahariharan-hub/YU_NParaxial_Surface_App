function results = demo_nparaxial_milestone254_scriptable_workflows_yu()
%DEMO_NPARAXIAL_MILESTONE254_SCRIPTABLE_WORKFLOWS_YU Workflow checks.

    testFolder = fileparts(mfilename('fullpath'));
    rootFolder = fileparts(testFolder);
    addpath(rootFolder);
    addpath(fullfile(rootFolder, 'core'));
    addpath(fullfile(rootFolder, 'workflows'));
    addpath(fullfile(rootFolder, 'examples'));

    numChecks = 0;
    prescription = nparaxial_default_prescription_yu("Single thin lens");
    raySettings = nparaxial_default_ray_settings_yu();
    raySettings.field_heights = [-5; 0; 5];

    traceOut = nparaxial_run_trace_workflow_yu(prescription, raySettings);
    assert(isstruct(traceOut) && strlength(traceOut.status) > 0, ...
        'Basic trace workflow should run and return a status.');
    numChecks = numChecks + 1;

    assert(isfield(traceOut, 'bundleSet') && ~isempty(traceOut.bundleSet) && ...
        isfield(traceOut.bundleSet, 'bundle') && ...
        ~isempty(traceOut.bundleSet(1).bundle), ...
        'Basic trace workflow should return traced bundles.');
    numChecks = numChecks + 1;

    assert(isfield(traceOut, 'image') && ...
        isfield(traceOut.image, 'type') && ...
        strlength(string(traceOut.image.type)) > 0, ...
        'Basic trace workflow should return image classification.');
    numChecks = numChecks + 1;

    assert(isempty(traceOut.validity) && ...
        ~any(traceOut.timing.section == "paraxial-validity diagnostics"), ...
        'Basic trace workflow should not compute validity by default.');
    numChecks = numChecks + 1;

    opts = struct('computeValidity', true);
    traceWithValidity = nparaxial_run_trace_workflow_yu( ...
        prescription, raySettings, opts);
    assert(~isempty(traceWithValidity.validity) && ...
        istable(traceWithValidity.validity.summary_table), ...
        'Trace workflow should compute validity only when requested.');
    numChecks = numChecks + 1;

    validityOut = nparaxial_run_validity_workflow_yu( ...
        prescription, raySettings);
    assert(~isempty(validityOut.validity.summary_table) && ...
        ~isempty(validityOut.validity.segment_table) && ...
        ~isempty(validityOut.validity.event_table), ...
        'Validity workflow should populate summary, segment, and event tables.');
    numChecks = numChecks + 1;

    directValidity = nparaxial_paraxial_validity_yu( ...
        validityOut.trace.bundleSet, validityOut.trace.prescription, [], 1e-12);
    assert(isequaln(validityOut.validity.summary_table, ...
        directValidity.summary_table) && ...
        isequaln(validityOut.validity.segment_table, ...
        directValidity.segment_table) && ...
        isequaln(validityOut.validity.event_table, directValidity.event_table), ...
        'Validity workflow should agree with the direct core validity call.');
    numChecks = numChecks + 1;

    sweepSettings = nparaxial_default_sweep_settings_yu();
    sweepSettings.n_field_points = 5;
    sweepOut = nparaxial_run_field_sweep_workflow_yu( ...
        prescription, sweepSettings, raySettings);
    assert(istable(sweepOut.sweep_table) && ~isempty(sweepOut.sweep_table), ...
        'Field-sweep workflow should return a non-empty sweep table.');
    numChecks = numChecks + 1;

    assert(timing_is_finite_local(traceOut.timing) && ...
        timing_is_finite_local(validityOut.timing) && ...
        timing_is_finite_local(sweepOut.timing), ...
        'Workflow timing outputs should be finite and nonnegative.');
    numChecks = numChecks + 1;

    nFiguresBefore = numel(findall(groot, 'Type', 'figure'));
    [traceExampleText, exTrace] = evalc('demo_script_trace_workflow_yu()');
    [validityExampleText, exValidity] = ...
        evalc('demo_script_validity_workflow_yu()');
    [sweepExampleText, exSweep] = ...
        evalc('demo_script_field_sweep_workflow_yu()');
    nFiguresAfter = numel(findall(groot, 'Type', 'figure'));
    assert(~isempty(exTrace.bundleSet) && ...
        ~isempty(exValidity.validity.summary_table) && ...
        ~isempty(exSweep.sweep_table) && nFiguresAfter == nFiguresBefore && ...
        strlength(traceExampleText) < 500 && ...
        strlength(validityExampleText) < 500 && ...
        strlength(sweepExampleText) < 500, ...
        'Example scripts should run without opening the app UI.');
    numChecks = numChecks + 1;

    [appSmoke, appChecks] = app_workflow_smoke_local(rootFolder);
    numChecks = numChecks + appChecks;

    results = struct();
    results.case_name = "milestone254_scriptable_workflows";
    results.num_checks = numChecks;
    results.app_smoke = appSmoke;
    results.trace_status = traceOut.status;
    results.validity_rows = height(validityOut.validity.summary_table);
    results.sweep_rows = height(sweepOut.sweep_table);
    results.trace_top_sections = top_sections_local(traceOut.timing, 5);
    results.validity_top_sections = top_sections_local(validityOut.timing, 5);
    results.sweep_top_sections = top_sections_local(sweepOut.timing, 5);
end


function tf = timing_is_finite_local(T)
    tf = istable(T) && ~isempty(T) && ...
        all(isfinite(T.total_elapsed_s)) && all(T.total_elapsed_s >= 0);
end


function sections = top_sections_local(T, n)
    if ~istable(T) || isempty(T)
        sections = strings(0, 1);
        return
    end
    n = min(n, height(T));
    sections = T.section(1:n);
end


function [status, numChecks] = app_workflow_smoke_local(rootFolder)
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

    status = "not_applicable_public_v2_tree";
    return
    cleanupApp = onCleanup(@() delete(app)); %#ok<NASGU>
    app.UIFigure.Visible = 'off';

    presetDropdown = find_dropdown_with_item_local( ...
        app.UIFigure, "Single thin lens");
    presetDropdown.Value = 'Single thin lens';
    presetButton = find_button_local(app.UIFigure, 'Load Default');
    call_callback_local(presetButton.ButtonPushedFcn, presetButton);
    drawnow limitrate

    runButton = find_button_local(app.UIFigure, 'Run Trace');
    call_callback_local(runButton.ButtonPushedFcn, runButton);
    drawnow limitrate
    timingAfterTrace = performance_table_local(app);
    assert(timing_call_count_local(timingAfterTrace, ...
        "paraxial-validity diagnostics") == 0, ...
        'Basic Run Trace should remain decoupled from validity diagnostics.');
    numChecks = numChecks + 1;

    updateValidityButton = find_by_tag_local( ...
        app.UIFigure, 'matlab.ui.control.Button', ...
        'nparaxial_update_validity_diagnostics');
    call_callback_local(updateValidityButton.ButtonPushedFcn, ...
        updateValidityButton);
    drawnow limitrate
    validityTable = find_by_tag_local(app.UIFigure, ...
        'matlab.ui.control.Table', 'nparaxial_validity_summary_table');
    assert(istable(validityTable.Data) && ~isempty(validityTable.Data), ...
        'Explicit app validity workflow should populate the summary table.');
    numChecks = numChecks + 1;

    updateSweepButton = find_by_tag_local( ...
        app.UIFigure, 'matlab.ui.control.Button', ...
        'nparaxial_update_validity_sweep');
    call_callback_local(updateSweepButton.ButtonPushedFcn, updateSweepButton);
    drawnow limitrate
    sweepTable = find_by_tag_local(app.UIFigure, ...
        'matlab.ui.control.Table', 'nparaxial_validity_sweep_table');
    assert(istable(sweepTable.Data) && ~isempty(sweepTable.Data), ...
        'Explicit app field-sweep workflow should populate the sweep table.');
    numChecks = numChecks + 1;

    status = "passed";
end


function T = performance_table_local(app)
    tab = find_tab_local(app.UIFigure, 'Performance');
    tab.Parent.SelectedTab = tab;
    call_callback_local(tab.Parent.SelectionChangedFcn, tab.Parent);
    drawnow limitrate
    perfTable = find_by_tag_local(app.UIFigure, ...
        'matlab.ui.control.Table', 'nparaxial_performance_table');
    T = perfTable.Data;
end


function count = timing_call_count_local(T, sectionName)
    count = 0;
    if ~istable(T) || isempty(T)
        return
    end
    idx = find(T.section == string(sectionName), 1);
    if ~isempty(idx)
        count = T.call_count(idx);
    end
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


function obj = find_by_tag_local(fig, className, tagValue)
    matches = findall(fig, '-isa', className, 'Tag', tagValue);
    if isempty(matches)
        error('Could not find %s tagged "%s".', className, tagValue);
    end
    obj = matches(1);
end


function tab = find_tab_local(fig, titleText)
    tabs = findall(fig, '-isa', 'matlab.ui.container.Tab', ...
        'Title', char(titleText));
    if isempty(tabs)
        error('Could not find tab "%s".', titleText);
    end
    tab = tabs(1);
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
