function results = demo_nparaxial_milestone245_field_sweep_stabilization_yu()
%DEMO_NPARAXIAL_MILESTONE245_FIELD_SWEEP_STABILIZATION_YU Stability checks.

    testFolder = fileparts(mfilename('fullpath'));
    rootFolder = fileparts(testFolder);
    addpath(rootFolder);
    addpath(fullfile(rootFolder, 'core'));

    numChecks = 0;

    test_invalid_normal_count_union_local();
    numChecks = numChecks + 1;

    test_sweep_csv_export_table_local(testFolder);
    numChecks = numChecks + 1;

    test_unbounded_aperture_limited_fallback_local();
    numChecks = numChecks + 1;

    appSmoke = app_smoke_local(rootFolder);
    if appSmoke == "passed"
        numChecks = numChecks + 1;
    end

    results = struct();
    results.case_name = "milestone245_field_sweep_stabilization";
    results.num_checks = numChecks;
    results.app_smoke = appSmoke;
end


function test_invalid_normal_count_union_local()
    events = table;
    events.invalid_surface_normal_flag = [true; true; false; false];
    events.invalid_hit_normal_flag = [true; false; true; false];

    count = nparaxial_count_row_union_flags_yu( ...
        events, ["invalid_surface_normal_flag", "invalid_hit_normal_flag"]);

    assert(count == 3, ...
        'Invalid-normal count should count each event row once.');
end


function test_sweep_csv_export_table_local(testFolder)
    p = prescription_local("D1", "dummy", 10, Inf);
    sweep = nparaxial_validity_field_sweep_yu( ...
        p, 0, [-2; 0; 2], ray_settings_local("Manual fixed-angle fan"), ...
        struct('z_final', 10), 1e-12);
    T = sweep.sweep_summary_table;

    tempBase = tempname(testFolder);
    filename = nparaxial_export_table_csv_yu(T, tempBase);
    cleanupObj = onCleanup(@() cleanup_temp_file_local(filename)); %#ok<NASGU>

    exported = readtable(filename);
    assert(height(exported) == height(T), ...
        'Exported field-sweep CSV should preserve row count.');
    assert_close_local(exported.y_field, T.y_field, ...
        'Exported field-sweep CSV should preserve y_field values.');
    assert(ismember('max_abs_translation_delta_y', ...
        exported.Properties.VariableNames), ...
        'Exported field-sweep CSV should preserve metric columns.');
end


function test_unbounded_aperture_limited_fallback_local()
    p = prescription_local("D1", "dummy", 10, Inf);
    sweep = nparaxial_validity_field_sweep_yu( ...
        p, 0, 0, ray_settings_local("Aperture-limited admitted cone"), ...
        struct('z_final', 10), 1e-12);
    T = sweep.sweep_summary_table;

    assert(T.n_rays_valid(1) > 0, ...
        'Unbounded aperture-limited sweep should fall back to finite rays.');
    assert(contains(T.status_text(1), "unbounded"), ...
        'Unbounded aperture-limited sweep should preserve fallback status.');
    assert(all(sweep.sweep_detail(1).rays.fallback_used), ...
        'Generated fallback rays should report fallback_used = true.');
end


function status = app_smoke_local(rootFolder)
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

    presetDropdown = find_dropdown_with_item_local(app.UIFigure, "Single thin lens");
    presetDropdown.Value = 'Single thin lens';
    presetButton = find_button_local(app.UIFigure, 'Load Default');
    call_callback_local(presetButton.ButtonPushedFcn, presetButton);
    drawnow limitrate

    runButton = find_button_local(app.UIFigure, 'Run Trace');
    call_callback_local(runButton.ButtonPushedFcn, runButton);
    drawnow limitrate

    validityMenu = assert_menu_local(app.UIFigure, "Show Paraxial Validity");
    call_callback_local(validityMenu(1).MenuSelectedFcn, validityMenu(1));
    drawnow limitrate

    updateButton = find_button_local(app.UIFigure, 'Update Validity Plot');
    call_callback_local(updateButton.ButtonPushedFcn, updateButton);
    drawnow limitrate

    sweepData = find_sweep_table_data_local(app.UIFigure);
    assert(~isempty(sweepData) && height(sweepData) > 0, ...
        'App should populate field-sweep table after update.');
    assert(abs(sweepData.y_field(1) + sweepData.y_field(end)) < 1e-12, ...
        'Default symmetric app sweep should span symmetric field limits.');

    metricDropdown = find_dropdown_with_item_local( ...
        app.UIFigure, "worst_angle_deg");
    metricDropdown.Value = 'worst_angle_deg';
    call_callback_local(metricDropdown.ValueChangedFcn, metricDropdown);
    drawnow limitrate
    assert(~isempty(find_sweep_table_data_local(app.UIFigure)), ...
        'Metric-only redraw should keep the stored sweep table.');
    assert_status_not_contains_local(app, ...
        "Inputs changed. Run Trace to refresh diagnostics.");

    sweepModeDropdown = find_dropdown_with_item_local( ...
        app.UIFigure, "Custom min/max field sweep");
    sweepModeDropdown.Value = 'Custom min/max field sweep';
    call_callback_local(sweepModeDropdown.ValueChangedFcn, sweepModeDropdown);
    drawnow limitrate
    assert(isempty(find_sweep_table_data_local(app.UIFigure)), ...
        'Sweep control changes should clear the stored sweep table.');
    assert_status_contains_local(app, ...
        "Field-sweep controls changed. Press Update Validity Plot to recompute.");

    exportButton = find_button_local(app.UIFigure, 'Export Field Sweep CSV');
    call_callback_local(exportButton.ButtonPushedFcn, exportButton);
    drawnow limitrate
    assert_status_contains_local(app, ...
        "Update Validity Plot before exporting field sweep.");

    call_callback_local(updateButton.ButtonPushedFcn, updateButton);
    drawnow limitrate
    assert(~isempty(find_sweep_table_data_local(app.UIFigure)), ...
        'Sweep update after control changes should not require a new optical trace.');
    assert_status_not_contains_local(app, ...
        "Inputs changed. Run Trace to refresh diagnostics.");

    status = "passed";
end


function settings = ray_settings_local(mode)
    settings = struct();
    settings.mode = string(mode);
    settings.n_rays = 5;
    settings.manual_u_max = 0.1;
end


function T = prescription_local(elementId, typeName, z, aperture)
    n = numel(string(elementId));
    T = table;
    T.element_id = string(elementId(:));
    T.event_order = (1:n).';
    T.type = string(typeName(:));
    T.z = double(z(:));
    T.aperture_radius = double(aperture(:));
    T.focal_length = Inf(n, 1);
    T.radius_R = Inf(n, 1);
    T.n_before = ones(n, 1);
    T.n_after = ones(n, 1);
    T.enabled = true(n, 1);
    T = nparaxial_validate_prescription_yu(T);
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


function button = find_button_local(fig, buttonText)
    buttons = findall(fig, '-isa', 'matlab.ui.control.Button', ...
        'Text', buttonText);
    assert(~isempty(buttons), 'Could not find button "%s".', buttonText);
    button = buttons(1);
end


function menu = assert_menu_local(fig, labelText)
    menu = findall(fig, '-isa', 'matlab.ui.container.Menu', ...
        'Text', labelText);
    assert(~isempty(menu), 'Could not find menu "%s".', labelText);
end


function call_callback_local(callbackFcn, source)
    if isempty(callbackFcn)
        error('UI callback was empty.');
    end
    if iscell(callbackFcn)
        callbackFcn{1}(source, [], callbackFcn{2:end});
    else
        callbackFcn(source, []);
    end
end


function T = find_sweep_table_data_local(fig)
    T = table();
    tables = findall(fig, '-isa', 'matlab.ui.control.Table');
    for k = 1:numel(tables)
        data = tables(k).Data;
        if istable(data) && ...
                ismember('max_abs_translation_delta_y', ...
                data.Properties.VariableNames)
            T = data;
            return
        end
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


function assert_status_not_contains_local(app, token)
    labels = findall(app.UIFigure, '-isa', 'matlab.ui.control.Label');
    texts = strings(numel(labels), 1);
    for k = 1:numel(labels)
        texts(k) = string(labels(k).Text);
    end
    assert(~any(contains(texts, token)), ...
        'App status unexpectedly contained "%s".', token);
end


function assert_close_local(actual, expected, message)
    actual = double(actual(:));
    expected = double(expected(:));
    assert(isequal(size(actual), size(expected)), ...
        'Arrays have different sizes.');
    assert(max(abs(actual - expected)) < 1e-12, message);
end


function cleanup_temp_file_local(filename)
    if exist(filename, 'file')
        delete(filename);
    end
end
