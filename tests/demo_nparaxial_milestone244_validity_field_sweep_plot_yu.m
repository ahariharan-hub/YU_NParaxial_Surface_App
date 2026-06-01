function results = demo_nparaxial_milestone244_validity_field_sweep_plot_yu()
%DEMO_NPARAXIAL_MILESTONE244_VALIDITY_FIELD_SWEEP_PLOT_YU Field sweep tests.

    testFolder = fileparts(mfilename('fullpath'));
    rootFolder = fileparts(testFolder);
    addpath(rootFolder);
    addpath(fullfile(rootFolder, 'core'));

    numChecks = 0;

    test_field_sweep_table_size_local();
    numChecks = numChecks + 1;

    test_translation_penalty_metric_local();
    numChecks = numChecks + 1;

    test_symmetric_field_array_local();
    numChecks = numChecks + 1;

    test_metric_extraction_local();
    numChecks = numChecks + 1;

    test_fully_vignetted_field_local();
    numChecks = numChecks + 1;

    test_unavailable_metric_local();
    numChecks = numChecks + 1;

    appSmoke = app_smoke_local(rootFolder);
    if appSmoke == "passed"
        numChecks = numChecks + 1;
    end

    results = struct();
    results.case_name = "milestone244_validity_field_sweep_plot";
    results.num_checks = numChecks;
    results.app_smoke = appSmoke;
end


function test_field_sweep_table_size_local()
    p = prescription_local("D1", "dummy", 10, Inf);
    fields = [-2; 0; 2; 4];
    sweep = nparaxial_validity_field_sweep_yu( ...
        p, 0, fields, ray_settings_local("Manual fixed-angle fan"), ...
        struct('z_final', 10), 1e-12);

    assert(height(sweep.sweep_summary_table) == numel(fields), ...
        'Sweep summary should have one row per field height.');
end


function test_translation_penalty_metric_local()
    p = prescription_local("D1", "dummy", 10, Inf);
    sweep = nparaxial_validity_field_sweep_yu( ...
        p, 0, [-1; 0; 1], ray_settings_local("Manual fixed-angle fan"), ...
        struct('z_final', 10), 1e-12);
    T = sweep.sweep_summary_table;
    expectedPos = 10*(tan(0.1) - 0.1);
    expectedNeg = 10*(tan(-0.1) - (-0.1));

    assert_close_local(T.max_abs_translation_delta_y, ...
        repmat(abs(expectedPos), height(T), 1), ...
        'max_abs_translation_delta_y should equal max |d*(tan(u)-u)|.');
    assert_close_local(T.worst_translation_delta_y, ...
        repmat(expectedNeg, height(T), 1), ...
        'Signed worst_translation_delta_y should preserve selected max-abs sign.');
end


function test_symmetric_field_array_local()
    yMax = 7;
    n = 5;
    fields = linspace(-yMax, yMax, n).';
    assert_close_local(fields, [-7; -3.5; 0; 3.5; 7], ...
        'Symmetric field sweep array should span [-Ymax, +Ymax].');
end


function test_metric_extraction_local()
    p = prescription_local("D1", "dummy", 10, Inf);
    sweep = nparaxial_validity_field_sweep_yu( ...
        p, 0, [-1; 0; 1], ray_settings_local("Manual fixed-angle fan"), ...
        struct('z_final', 10), 1e-12);
    T = sweep.sweep_summary_table;

    [maxAbsMetric, status] = nparaxial_validity_field_sweep_metric_yu( ...
        T, "max_abs_translation_delta_y");
    assert(status == "Metric available.", ...
        'Available field-sweep metric should report available status.');
    assert(all(maxAbsMetric >= 0), ...
        'max_abs_translation_delta_y metric should be nonnegative.');

    [signedMetric, status] = nparaxial_validity_field_sweep_metric_yu( ...
        T, "worst_translation_delta_y");
    assert(status == "Metric available.", ...
        'Signed field-sweep metric should report available status.');
    assert(any(signedMetric < 0), ...
        'Signed worst_translation_delta_y should preserve sign.');
end


function test_fully_vignetted_field_local()
    p = prescription_local("STOP", "stop", 0, 1);
    sweep = nparaxial_validity_field_sweep_yu( ...
        p, 0, 10, ray_settings_local("Aperture-limited admitted cone"), ...
        struct('z_final', 10), 1e-12);
    T = sweep.sweep_summary_table;

    assert(T.n_rays_valid(1) == 0, ...
        'Fully vignetted field should have no valid rays.');
    assert(isnan(T.max_abs_translation_delta_y(1)), ...
        'Fully vignetted field should leave plot metrics NaN.');
    assert(contains(T.status_text(1), "fully vignetted"), ...
        'Fully vignetted row should include clear status text.');
end


function test_unavailable_metric_local()
    p = prescription_local("D1", "dummy", 10, Inf);
    sweep = nparaxial_validity_field_sweep_yu( ...
        p, 0, [-1; 0; 1], ray_settings_local("Manual fixed-angle fan"), ...
        struct('z_final', 10), 1e-12);

    [values, status] = nparaxial_validity_field_sweep_metric_yu( ...
        sweep.sweep_summary_table, "not_a_metric");
    assert(all(isnan(values)), ...
        'Unavailable metric should return NaN values.');
    assert(contains(status, "unavailable"), ...
        'Unavailable metric should return clear status text.');
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
    presetButton = findall(app.UIFigure, ...
        '-isa', 'matlab.ui.control.Button', 'Text', 'Load Default');
    call_callback_local(presetButton(1).ButtonPushedFcn, presetButton(1));
    drawnow limitrate

    runButton = findall(app.UIFigure, ...
        '-isa', 'matlab.ui.control.Button', 'Text', 'Run Trace');
    call_callback_local(runButton(1).ButtonPushedFcn, runButton(1));
    drawnow limitrate

    validityMenu = assert_menu_local(app.UIFigure, "Show Paraxial Validity");
    call_callback_local(validityMenu(1).MenuSelectedFcn, validityMenu(1));
    drawnow limitrate

    metricDropdown = find_dropdown_with_item_local( ...
        app.UIFigure, "max_abs_translation_delta_y");
    assert(any(string(metricDropdown.Items) == "worst_angle_deg"), ...
        'Validity metric dropdown should contain expected metrics.');

    updateButton = findall(app.UIFigure, ...
        '-isa', 'matlab.ui.control.Button', 'Text', 'Update Validity Plot');
    assert(~isempty(updateButton), ...
        'Update Validity Plot button should exist.');
    call_callback_local(updateButton(1).ButtonPushedFcn, updateButton(1));
    drawnow limitrate

    axesList = findall(app.UIFigure, '-isa', 'matlab.ui.control.UIAxes');
    assert(numel(axesList) >= 2, ...
        'Paraxial Validity tab should add plotting axes.');

    oldPrescription = findall(app.UIFigure, ...
        '-isa', 'matlab.ui.control.Table');
    metricDropdown.Value = 'worst_angle_deg';
    call_callback_local(metricDropdown.ValueChangedFcn, metricDropdown);
    drawnow limitrate
    assert_status_not_contains_local(app, ...
        "Inputs changed. Run Trace to refresh diagnostics.");

    newPrescription = findall(app.UIFigure, ...
        '-isa', 'matlab.ui.control.Table');
    assert(numel(newPrescription) == numel(oldPrescription), ...
        'Metric refresh should not alter prescription/table structure.');

    status = "passed";
end


function settings = ray_settings_local(mode)
    settings = struct();
    settings.mode = string(mode);
    settings.n_rays = 3;
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
        callbackFcn{1}(source, []);
    else
        callbackFcn(source, []);
    end
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
