function results = demo_nparaxial_milestone253_decouple_validity_from_trace_yu()
%DEMO_NPARAXIAL_MILESTONE253_DECOUPLE_VALIDITY_FROM_TRACE_YU App-flow checks.

    testFolder = fileparts(mfilename('fullpath'));
    rootFolder = fileparts(testFolder);
    addpath(rootFolder);
    addpath(fullfile(rootFolder, 'core'));

    numChecks = 0;
    [appSmoke, timingOff, timingExplicit, timingAuto, appChecks, ...
            basicOffTime, explicitValidityTime, autoTotalTime] = ...
        app_decoupling_smoke_local(rootFolder);
    numChecks = numChecks + appChecks;

    results = struct();
    results.case_name = "milestone253_decouple_validity_from_trace";
    results.num_checks = numChecks;
    results.app_smoke = appSmoke;
    results.default_basic_run_trace_s = basicOffTime;
    results.explicit_validity_update_s = explicitValidityTime;
    results.auto_validity_run_trace_s = autoTotalTime;
    results.default_top_sections = top_sections_local(timingOff, 5);
    results.explicit_top_sections = top_sections_local(timingExplicit, 5);
    results.auto_top_sections = top_sections_local(timingAuto, 5);
end


function [status, timingOff, timingExplicit, timingAuto, numChecks, ...
        basicOffTime, explicitValidityTime, autoTotalTime] = ...
        app_decoupling_smoke_local(rootFolder)

    status = "skipped";
    timingOff = table();
    timingExplicit = table();
    timingAuto = table();
    numChecks = 0;
    basicOffTime = NaN;
    explicitValidityTime = NaN;
    autoTotalTime = NaN;
    if ~usejava('awt')
        return
    end

    oldPath = path;
    cleanupPath = onCleanup(@() path(oldPath)); %#ok<NASGU>
    addpath(rootFolder);
    addpath(fullfile(rootFolder, 'core'));

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

    timingOff = performance_table_local(app);
    assert(timing_call_count_local(timingOff, ...
        "paraxial-validity diagnostics") == 0, ...
        'Default Run Trace should not compute full validity diagnostics.');
    numChecks = numChecks + 1;
    assert(timing_call_count_local(timingOff, ...
        "field-sweep calculation") == 0, ...
        'Run Trace should not automatically compute the validity field sweep.');
    basicOffTime = timing_total_local(timingOff, "Basic Run Trace");
    assert(isfinite(basicOffTime) && basicOffTime >= 0, ...
        'Default Run Trace should record Basic Run Trace timing.');
    numChecks = numChecks + 1;

    validityTab = find_tab_local(app.UIFigure, 'Paraxial Validity');
    validityTab.Parent.SelectedTab = validityTab;
    call_callback_local(validityTab.Parent.SelectionChangedFcn, ...
        validityTab.Parent);
    drawnow limitrate
    staleText = validity_text_local(app.UIFigure);
    assert(any(contains(staleText, ...
        "Paraxial validity diagnostics are stale. Press Update Validity Diagnostics.")), ...
        'Validity tab should show a stale diagnostics message after basic trace.');
    assert(isempty(validity_summary_table_local(app.UIFigure)), ...
        'Validity summary table should remain empty until explicit update.');
    numChecks = numChecks + 1;

    exportMenu = assert_menu_local(app.UIFigure, ...
        "Export Paraxial Validity CSV");
    call_callback_local(exportMenu(1).MenuSelectedFcn, exportMenu(1));
    drawnow limitrate
    assert_status_contains_local(app, ...
        "Update Validity Diagnostics before exporting paraxial-validity data.");
    numChecks = numChecks + 1;

    directValidity = direct_validity_for_single_lens_local();
    updateValidityButton = find_by_tag_local( ...
        app.UIFigure, 'matlab.ui.control.Button', ...
        'nparaxial_update_validity_diagnostics');
    call_callback_local(updateValidityButton.ButtonPushedFcn, ...
        updateValidityButton);
    drawnow limitrate

    summaryTable = validity_summary_table_local(app.UIFigure);
    segmentTable = validity_segment_table_local(app.UIFigure);
    eventTable = validity_event_table_local(app.UIFigure);
    assert(~isempty(summaryTable) && ~isempty(segmentTable) && ...
        ~isempty(eventTable), ...
        'Explicit validity update should populate summary, segment, and event tables.');
    numChecks = numChecks + 1;

    assert(isequaln(summaryTable, directValidity.summary_table) && ...
        isequaln(segmentTable, directValidity.segment_table) && ...
        isequaln(eventTable, directValidity.event_table), ...
        'Explicit validity diagnostics should match the direct core helper output.');
    timingExplicit = performance_table_local(app);
    assert(timing_call_count_local(timingExplicit, ...
        "Explicit Paraxial Validity update") == 1, ...
        'Explicit validity update should record its timing section.');
    explicitValidityTime = timing_total_local( ...
        timingExplicit, "Explicit Paraxial Validity update");
    numChecks = numChecks + 1;

    rayTab = find_tab_local(app.UIFigure, 'Ray Diagram');
    rayTab.Parent.SelectedTab = rayTab;
    call_callback_local(rayTab.Parent.SelectionChangedFcn, rayTab.Parent);
    drawnow limitrate
    beforeDisplayOnlyCount = timing_call_count_local( ...
        performance_table_local(app), "paraxial-validity diagnostics");
    surfaceCheckbox = find_checkbox_local(app.UIFigure, "Surface curves");
    surfaceCheckbox.Value = ~surfaceCheckbox.Value;
    call_callback_local(surfaceCheckbox.ValueChangedFcn, surfaceCheckbox);
    drawnow limitrate
    cardinalCheckbox = find_checkbox_local(app.UIFigure, "Show cardinal points");
    cardinalCheckbox.Value = ~cardinalCheckbox.Value;
    call_callback_local(cardinalCheckbox.ValueChangedFcn, cardinalCheckbox);
    drawnow limitrate
    afterDisplayOnlyTiming = performance_table_local(app);
    assert(timing_call_count_local(afterDisplayOnlyTiming, ...
        "paraxial-validity diagnostics") == beforeDisplayOnlyCount, ...
        'Display-only plot options should not recompute validity diagnostics.');
    assert(isequaln(summaryTable, validity_summary_table_local(app.UIFigure)), ...
        'Display-only plot options should not invalidate computed validity tables.');
    numChecks = numChecks + 1;

    rayFanDropdown = find_dropdown_with_item_local( ...
        app.UIFigure, "Aperture-limited admitted cone");
    rayFanDropdown.Value = 'Aperture-limited admitted cone';
    call_callback_local(rayFanDropdown.ValueChangedFcn, rayFanDropdown);
    drawnow limitrate
    call_callback_local(runButton.ButtonPushedFcn, runButton);
    drawnow limitrate
    validityTab.Parent.SelectedTab = validityTab;
    call_callback_local(validityTab.Parent.SelectionChangedFcn, ...
        validityTab.Parent);
    drawnow limitrate
    assert(isempty(validity_summary_table_local(app.UIFigure)) && ...
        any(contains(validity_text_local(app.UIFigure), ...
        "Paraxial validity diagnostics are stale")), ...
        'Changing ray fan settings should leave validity stale after default Run Trace.');
    numChecks = numChecks + 1;
    assert(isempty(validity_sweep_table_local(app.UIFigure)), ...
        'Run Trace should not automatically populate field-sweep results.');
    numChecks = numChecks + 1;

    autoCheckbox = find_by_tag_local( ...
        app.UIFigure, 'matlab.ui.control.CheckBox', ...
        'nparaxial_auto_validity_after_trace');
    autoCheckbox.Value = true;
    call_callback_local(autoCheckbox.ValueChangedFcn, autoCheckbox);
    drawnow limitrate
    call_callback_local(runButton.ButtonPushedFcn, runButton);
    drawnow limitrate
    timingAuto = performance_table_local(app);
    assert(timing_call_count_local(timingAuto, ...
        "Run Trace automatic validity") == 1 && ...
        timing_call_count_local(timingAuto, ...
        "paraxial-validity diagnostics") == 1, ...
        'Automatic validity option should compute diagnostics during Run Trace.');
    assert(~isempty(validity_summary_table_local(app.UIFigure)), ...
        'Automatic validity option should populate validity tables after Run Trace.');
    numChecks = numChecks + 1;
    assert(timing_call_count_local(timingAuto, ...
        "field-sweep calculation") == 0, ...
        'Automatic validity option should not compute field sweep.');
    numChecks = numChecks + 1;
    autoValidityTime = timing_total_local( ...
        timingAuto, "Run Trace automatic validity");
    autoTotalTime = timing_total_local( ...
        timingAuto, "Run Trace with automatic validity");
    assert(isfinite(autoValidityTime) && autoValidityTime > 0 && ...
        isfinite(autoTotalTime) && autoTotalTime >= autoValidityTime, ...
        'Run Trace with automatic validity should include additional validity timing.');
    numChecks = numChecks + 1;

    status = "passed";
end


function validity = direct_validity_for_single_lens_local()
    params = struct();
    params.z_obj = -120;
    params.y_min = -5;
    params.y_max = 5;
    params.Nfield = 5;
    params.Nrays = 9;
    params.manual_u_max = 0.04;

    prescription = nparaxial_validate_prescription_yu( ...
        nparaxial_default_prescription_yu("Single thin lens"));
    img = nparaxial_solve_image_plane_yu(prescription, params.z_obj);
    zTrace = img.trace_z_final;
    yFields = linspace(params.y_min, params.y_max, params.Nfield).';
    bundleSet = struct([]);
    for q = 1:numel(yFields)
        rays = nparaxial_make_manual_fan_rays_yu( ...
            params.z_obj, yFields(q), params.Nrays, ...
            params.manual_u_max);
        rays.name = "field_" + string(q) + "_" + rays.name;
        rays.ray_name = rays.name;
        bundleSet(q).field_index = q; %#ok<AGROW>
        bundleSet(q).y_obj = yFields(q); %#ok<AGROW>
        bundleSet(q).rays = rays; %#ok<AGROW>
        bundleSet(q).bundle = nparaxial_trace_bundle_yu( ...
            rays, prescription, zTrace); %#ok<AGROW>
    end
    validity = nparaxial_paraxial_validity_yu( ...
        bundleSet, prescription, [], 1e-12);
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


function texts = validity_text_local(fig)
    textArea = find_by_tag_local(fig, ...
        'matlab.ui.control.TextArea', 'nparaxial_validity_text');
    texts = string(textArea.Value(:));
end


function T = validity_summary_table_local(fig)
    T = tagged_table_data_local(fig, 'nparaxial_validity_summary_table');
end


function T = validity_segment_table_local(fig)
    T = tagged_table_data_local(fig, 'nparaxial_validity_segment_table');
end


function T = validity_event_table_local(fig)
    T = tagged_table_data_local(fig, 'nparaxial_validity_event_table');
end


function T = validity_sweep_table_local(fig)
    T = tagged_table_data_local(fig, 'nparaxial_validity_sweep_table');
    if isempty(T)
        tables = findall(fig, '-isa', 'matlab.ui.control.Table');
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
end


function T = tagged_table_data_local(fig, tagValue)
    T = table();
    matches = findall(fig, '-isa', 'matlab.ui.control.Table', ...
        'Tag', tagValue);
    if isempty(matches)
        return
    end
    if istable(matches(1).Data)
        T = matches(1).Data;
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


function menu = assert_menu_local(fig, label)
    menu = findall(fig, '-isa', 'matlab.ui.container.Menu', ...
        'Text', char(label));
    assert(~isempty(menu), 'Could not find menu "%s".', label);
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
