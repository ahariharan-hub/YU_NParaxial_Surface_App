function results = demo_nparaxial_milestone251_validity_field_sweep_cache_yu()
%DEMO_NPARAXIAL_MILESTONE251_VALIDITY_FIELD_SWEEP_CACHE_YU Cache checks.

    testFolder = fileparts(mfilename('fullpath'));
    rootFolder = fileparts(testFolder);
    addpath(rootFolder);
    addpath(fullfile(rootFolder, 'core'));

    numChecks = 0;

    p = nparaxial_default_prescription_yu("single thin lens");
    sig1 = nparaxial_prescription_signature_yu(p);
    p.aperture_radius(1) = p.aperture_radius(1) + 1;
    sig2 = nparaxial_prescription_signature_yu(p);
    assert(strlength(sig1) > 0 && sig1 ~= sig2, ...
        'Prescription signature should change when aperture data changes.');
    numChecks = numChecks + 1;

    [appSmoke, timingAfterCache, repeatedReuseRatio, appChecks] = ...
        app_cache_smoke_local(rootFolder);
    if appSmoke == "passed"
        requiredSections = [
            "field-sweep calculation"
            "field-sweep cache reuse"
            "paraxial-validity diagnostics"
            "ray tracing"
            "Ray Diagram redraw"
        ];
        assert(all(ismember(requiredSections, timingAfterCache.section)), ...
            'Performance timing should retain sweep, validity, trace, and redraw sections.');
        numChecks = numChecks + 1;
    end

    results = struct();
    results.case_name = "milestone251_validity_field_sweep_cache";
    results.num_checks = numChecks + appChecks;
    results.app_smoke = appSmoke;
    results.repeated_update_reuse_ratio = repeatedReuseRatio;
    results.top_slow_sections = top_sections_local(timingAfterCache, 5);
end


function [status, timingTable, reuseRatio, numChecks] = app_cache_smoke_local(rootFolder)
    status = "skipped";
    timingTable = table();
    reuseRatio = NaN;
    numChecks = 0;
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

    presetDropdown = find_dropdown_with_item_local( ...
        app.UIFigure, "Single thin lens");
    presetDropdown.Value = 'Single thin lens';
    presetButton = find_button_local(app.UIFigure, 'Load Default');
    call_callback_local(presetButton.ButtonPushedFcn, presetButton);
    drawnow limitrate

    runButton = find_button_local(app.UIFigure, 'Run Trace');
    call_callback_local(runButton.ButtonPushedFcn, runButton);
    drawnow limitrate

    updateValidityButton = find_by_tag_local( ...
        app.UIFigure, 'matlab.ui.control.Button', ...
        'nparaxial_update_validity_diagnostics');
    call_callback_local(updateValidityButton.ButtonPushedFcn, ...
        updateValidityButton);
    drawnow limitrate

    updateSweepButton = find_by_tag_local( ...
        app.UIFigure, 'matlab.ui.control.Button', ...
        'nparaxial_update_validity_sweep');
    call_callback_local(updateSweepButton.ButtonPushedFcn, updateSweepButton);
    drawnow limitrate
    uncachedTable = find_sweep_table_data_local(app.UIFigure);
    assert(~isempty(uncachedTable), ...
        'Initial field-sweep update should populate the sweep table.');
    timingAfterFirst = performance_table_local(app);
    firstCalculationCount = timing_call_count_local( ...
        timingAfterFirst, "field-sweep calculation");
    firstCalculationTime = timing_total_local( ...
        timingAfterFirst, "field-sweep calculation");

    call_callback_local(updateSweepButton.ButtonPushedFcn, updateSweepButton);
    drawnow limitrate
    cachedTable = find_sweep_table_data_local(app.UIFigure);
    timingAfterSecond = performance_table_local(app);
    secondCalculationCount = timing_call_count_local( ...
        timingAfterSecond, "field-sweep calculation");
    cacheReuseTime = timing_total_local( ...
        timingAfterSecond, "field-sweep cache reuse");
    assert(isequaln(uncachedTable, cachedTable), ...
        'Cached repeated update should keep the sweep table numerically identical.');
    assert(secondCalculationCount == firstCalculationCount, ...
        'Repeated Update Validity Plot should reuse the cached sweep.');
    reuseRatio = cacheReuseTime / max(firstCalculationTime, eps);
    numChecks = numChecks + 1;

    metricDropdown = find_by_tag_local( ...
        app.UIFigure, 'matlab.ui.control.DropDown', ...
        'nparaxial_validity_sweep_metric');
    metricDropdown.Value = 'worst_angle_deg';
    call_callback_local(metricDropdown.ValueChangedFcn, metricDropdown);
    drawnow limitrate
    metricTable = find_sweep_table_data_local(app.UIFigure);
    timingAfterMetric = performance_table_local(app);
    assert(isequaln(cachedTable, metricTable), ...
        'Metric-only changes should redraw the existing sweep table.');
    assert(timing_call_count_local(timingAfterMetric, ...
        "field-sweep calculation") == firstCalculationCount, ...
        'Metric-only changes should not recompute the sweep.');
    numChecks = numChecks + 1;

    cardinalCheckbox = find_checkbox_local(app.UIFigure, "Show cardinal points");
    cardinalCheckbox.Value = true;
    call_callback_local(cardinalCheckbox.ValueChangedFcn, cardinalCheckbox);
    drawnow limitrate
    overlayTable = find_sweep_table_data_local(app.UIFigure);
    timingAfterOverlay = performance_table_local(app);
    assert(isequaln(metricTable, overlayTable), ...
        'Display-only overlay changes should not invalidate the sweep table.');
    assert(timing_call_count_local(timingAfterOverlay, ...
        "field-sweep calculation") == firstCalculationCount, ...
        'Display-only overlay changes should not recompute field-sweep traces.');
    numChecks = numChecks + 1;

    exportSweepButton = find_by_tag_local( ...
        app.UIFigure, 'matlab.ui.control.Button', ...
        'nparaxial_export_validity_sweep');
    countField = find_by_tag_local( ...
        app.UIFigure, 'matlab.ui.control.NumericEditField', ...
        'nparaxial_validity_sweep_count');
    countField.Value = countField.Value + 2;
    call_callback_local(countField.ValueChangedFcn, countField);
    drawnow limitrate
    assert(isempty(find_sweep_table_data_local(app.UIFigure)), ...
        'Changing field point count should mark the sweep stale and clear display.');
    call_callback_local(exportSweepButton.ButtonPushedFcn, exportSweepButton);
    drawnow limitrate
    assert_status_contains_local(app, ...
        "Update Validity Plot before exporting field sweep.");
    numChecks = numChecks + 1;

    call_callback_local(updateSweepButton.ButtonPushedFcn, updateSweepButton);
    drawnow limitrate
    changedCountTable = find_sweep_table_data_local(app.UIFigure);
    timingAfterRecompute = performance_table_local(app);
    assert(height(changedCountTable) == height(uncachedTable) + 2, ...
        'Changing field point count should recompute a different-sized sweep.');
    assert(timing_call_count_local(timingAfterRecompute, ...
        "field-sweep calculation") == firstCalculationCount + 1, ...
        'Stale field-sweep inputs should trigger recomputation.');
    numChecks = numChecks + 1;

    presetDropdown.Value = 'Two thin lenses';
    call_callback_local(presetButton.ButtonPushedFcn, presetButton);
    drawnow limitrate
    assert(isempty(find_sweep_table_data_local(app.UIFigure)), ...
        'Changing prescription should invalidate the field-sweep cache/display.');
    numChecks = numChecks + 1;

    timingTable = timingAfterRecompute;
    status = "passed";
end


function T = find_sweep_table_data_local(fig)
    tables = findall(fig, '-isa', 'matlab.ui.control.Table');
    T = table();
    for k = 1:numel(tables)
        candidate = tables(k).Data;
        if istable(candidate)
            names = string(candidate.Properties.VariableNames);
            if all(ismember(["y_field", "worst_angle_deg", ...
                    "status_text"], names))
                T = candidate;
                return
            end
        end
    end
end


function T = performance_table_local(app)
    tab = find_tab_local(app.UIFigure, 'Performance');
    tab.Parent.SelectedTab = tab;
    if ~isempty(tab.Parent.SelectionChangedFcn)
        call_callback_local(tab.Parent.SelectionChangedFcn, tab.Parent);
    end
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


function total = timing_total_local(T, sectionName)
    total = 0;
    if ~istable(T) || isempty(T)
        return
    end
    idx = find(T.section == string(sectionName), 1);
    if ~isempty(idx)
        total = T.total_elapsed_s(idx);
    end
end


function sections = top_sections_local(T, n)
    if ~istable(T) || isempty(T)
        sections = strings(0, 1);
        return
    end
    n = min(n, height(T));
    sections = T.section(1:n);
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


function assert_status_contains_local(app, token)
    labels = findall(app.UIFigure, '-isa', 'matlab.ui.control.Label');
    texts = strings(numel(labels), 1);
    for k = 1:numel(labels)
        texts(k) = string(labels(k).Text);
    end
    assert(any(contains(texts, token)), ...
        'App status did not contain "%s".', token);
end
