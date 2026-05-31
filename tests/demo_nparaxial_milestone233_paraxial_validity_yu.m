function results = demo_nparaxial_milestone233_paraxial_validity_yu()
%DEMO_NPARAXIAL_MILESTONE233_PARAXIAL_VALIDITY_YU Validity diagnostics.

    testFolder = fileparts(mfilename('fullpath'));
    rootFolder = fileparts(testFolder);
    addpath(rootFolder);
    addpath(fullfile(rootFolder, 'core'));

    numChecks = 0;

    test_translation_penalty_local();
    numChecks = numChecks + 1;

    test_zero_small_angle_local();
    numChecks = numChecks + 1;

    test_plane_refraction_local();
    numChecks = numChecks + 1;

    test_plane_refraction_tir_local();
    numChecks = numChecks + 1;

    test_thinlens_diagnostic_local();
    numChecks = numChecks + 1;

    test_surface_deferral_local();
    numChecks = numChecks + 1;

    test_same_z_event_order_local();
    numChecks = numChecks + 1;

    test_blocked_ray_no_downstream_rows_local();
    numChecks = numChecks + 1;

    appSmoke = app_smoke_local(rootFolder);
    if appSmoke == "passed"
        numChecks = numChecks + 1;
    end

    results = struct();
    results.case_name = "milestone233_paraxial_validity";
    results.num_checks = numChecks;
    results.app_smoke = appSmoke;
end


function test_translation_penalty_local()
    p = prescription_local("D1", 1, "dummy", 10, Inf, Inf, Inf, 1, 1);
    rays = table;
    rays.name = ["pos"; "neg"];
    rays.z0 = [0; 0];
    rays.y0 = [0; 0];
    rays.u0 = [0.1; -0.1];
    bundleSet = bundle_set_local(rays, p, 10);
    seg = nparaxial_trace_segments_table_yu(bundleSet);
    seg = seg(abs(seg.d) > 0, :);

    expected = 10 * (tan(rays.u0) - rays.u0);
    assert_close_local(seg.delta_y_translation(1), expected(1), ...
        'Positive-u translation penalty sign mismatch.');
    assert_close_local(seg.delta_y_translation(2), expected(2), ...
        'Negative-u translation penalty sign mismatch.');
end


function test_zero_small_angle_local()
    metrics = nparaxial_angle_validity_metrics_yu(0);
    level = nparaxial_validity_warning_level_yu( ...
        0, metrics.relative_tan_error);
    assert(isfinite(metrics.relative_tan_error), ...
        'u = 0 should not produce Inf relative tan error.');
    assert(isfinite(metrics.relative_sin_error), ...
        'u = 0 should not produce Inf relative sin error.');
    assert(level == "ok", 'u = 0 warning level should be ok.');
end


function test_plane_refraction_local()
    diag = nparaxial_plane_refraction_validity_yu(1, 1.5, 0.2);
    expected = asin((1/1.5)*sin(0.2)) - (1/1.5)*0.2;
    assert_close_local(diag.delta_u, expected, ...
        'Plane refraction delta_u mismatch.');
    assert(~diag.tir_flag, 'n1 < n2 plane refraction should not TIR.');
end


function test_plane_refraction_tir_local()
    diag = nparaxial_plane_refraction_validity_yu(1.5, 1, 1.0);
    assert(diag.tir_flag, 'Plane refraction should flag TIR.');
    assert(diag.warning_level == "severe", ...
        'TIR should produce severe warning level.');
end


function test_thinlens_diagnostic_local()
    diag = nparaxial_thinlens_validity_yu(2, 0.01, 50);
    assert_close_local(diag.deflection, -2/50, ...
        'Thin-lens deflection should be -y/f.');
    assert_close_local(diag.u_out, 0.01 - 2/50, ...
        'Thin-lens u_out should be u_in - y/f.');
    assert(contains(diag.note, "no unique exact Snell reference"), ...
        'Thin-lens note must not claim an exact Snell comparison.');
end


function test_surface_deferral_local()
    p = prescription_local("S1", 1, "surface", 10, Inf, Inf, 40, 1, 1.5);
    rays = ray_table_local("ray1", 0, 1, 0.02);
    validity = nparaxial_paraxial_validity_yu( ...
        bundle_set_local(rays, p, 10), p);
    assert(any(validity.event_table.diagnostic_type == ...
        "spherical_surface_deferred"), ...
        'Finite-R surface should defer spherical scalar validity.');
    assert(any(contains(validity.event_table.note, "2.3.4")), ...
        'Finite-R surface deferral should name Milestone 2.3.4.');
end


function test_same_z_event_order_local()
    p = prescription_local( ...
        ["Lslow"; "Lfast"], [2; 1], ["thinlens"; "thinlens"], ...
        [10; 10], [Inf; Inf], [100; 200], [Inf; Inf], [1; 1], [1; 1]);
    rays = ray_table_local("ray1", 0, 1, 0.01);
    validity = nparaxial_paraxial_validity_yu( ...
        bundle_set_local(rays, p, 20), p);
    assert(isequal(validity.event_table.element_id(:), ["Lfast"; "Lslow"]), ...
        'Event validity should preserve z, event_order, row ordering.');
end


function test_blocked_ray_no_downstream_rows_local()
    p = prescription_local( ...
        ["STOP"; "L1"], [1; 2], ["stop"; "thinlens"], ...
        [10; 20], [0.5; Inf], [Inf; 100], [Inf; Inf], [1; 1], [1; 1]);
    rays = ray_table_local("blocked", 0, 1, 0);
    validity = nparaxial_paraxial_validity_yu( ...
        bundle_set_local(rays, p, 30), p);
    assert(any(validity.event_table.diagnostic_type == "blocked_at_aperture"), ...
        'Blocked ray should report aperture blocking event.');
    assert(~any(validity.event_table.element_id == "L1"), ...
        'Blocked ray should not fabricate downstream event diagnostics.');
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

    presetDropdown = find_dropdown_with_item_local(app.UIFigure, 'Single thin lens');
    presetDropdown.Value = 'Single thin lens';
    loadButton = findall(app.UIFigure, ...
        '-isa', 'matlab.ui.control.Button', 'Text', 'Load Default');
    assert(~isempty(loadButton), ...
        'App smoke test could not find Load Default button.');
    call_callback_local(loadButton(1).ButtonPushedFcn, loadButton(1));

    runButton = findall(app.UIFigure, ...
        '-isa', 'matlab.ui.control.Button', 'Text', 'Run Trace');
    assert(~isempty(runButton), ...
        'App smoke test could not find Run Trace button.');
    call_callback_local(runButton(1).ButtonPushedFcn, runButton(1));
    drawnow limitrate

    validityMenu = assert_menu_local(app.UIFigure, "Show Paraxial Validity");
    call_callback_local(validityMenu(1).MenuSelectedFcn, validityMenu(1));
    drawnow limitrate

    validityTab = findall(app.UIFigure, ...
        '-isa', 'matlab.ui.container.Tab', 'Title', 'Paraxial Validity');
    assert(~isempty(validityTab), ...
        'App smoke test could not find the Paraxial Validity tab.');

    tables = findall(app.UIFigure, '-isa', 'matlab.ui.control.Table');
    assert(any(arrayfun(@is_validity_summary_table_local, tables)), ...
        'Paraxial Validity tab did not populate the summary table.');
    assert(any(arrayfun(@is_validity_event_table_local, tables)), ...
        'Paraxial Validity tab did not populate the event table.');

    numericFields = findall(app.UIFigure, ...
        '-isa', 'matlab.ui.control.NumericEditField');
    numericFields(1).Value = numericFields(1).Value + 1;
    call_callback_local(numericFields(1).ValueChangedFcn, numericFields(1));
    drawnow limitrate

    exportMenu = assert_menu_local(app.UIFigure, "Export Paraxial Validity CSV");
    call_callback_local(exportMenu(1).MenuSelectedFcn, exportMenu(1));
    drawnow limitrate
    assert_status_contains_local(app, ...
        "Inputs changed. Run Trace to refresh diagnostics.");

    status = "passed";
end


function bundleSet = bundle_set_local(rays, prescription, zFinal)
    bundleSet = struct();
    bundleSet.field_index = 1;
    bundleSet.y_obj = rays.y0(1);
    bundleSet.rays = rays;
    bundleSet.bundle = nparaxial_trace_bundle_yu(rays, prescription, zFinal);
end


function rays = ray_table_local(name, z0, y0, u0)
    rays = table;
    rays.name = string(name(:));
    rays.z0 = double(z0(:));
    rays.y0 = double(y0(:));
    rays.u0 = double(u0(:));
    rays.sampling_mode = repmat("test", height(rays), 1);
end


function p = prescription_local( ...
    elementId, eventOrder, typeName, z, aperture, f, R, nBefore, nAfter)

    n = numel(string(elementId));
    p = table;
    p.element_id = string(elementId(:));
    p.event_order = expand_double_local(eventOrder, n);
    p.type = string(typeName(:));
    p.z = expand_double_local(z, n);
    p.aperture_radius = expand_double_local(aperture, n);
    p.focal_length = expand_double_local(f, n);
    p.radius_R = expand_double_local(R, n);
    p.n_before = expand_double_local(nBefore, n);
    p.n_after = expand_double_local(nAfter, n);
    p.enabled = true(n, 1);
    p = nparaxial_validate_prescription_yu(p);
end


function values = expand_double_local(values, n)
    values = double(values(:));
    if isscalar(values) && n > 1
        values = repmat(values, n, 1);
    end
end


function assert_close_local(actual, expected, message)
    assert(abs(actual - expected) < 1e-12, message);
end


function tf = is_validity_summary_table_local(uiTable)
    data = uiTable.Data;
    tf = istable(data) && all(ismember( ...
        ["ray_name", "worst_warning_level", "worst_translation_delta_y"], ...
        string(data.Properties.VariableNames))) && height(data) > 0;
end


function tf = is_validity_event_table_local(uiTable)
    data = uiTable.Data;
    tf = istable(data) && all(ismember( ...
        ["diagnostic_type", "warning_level", "note"], ...
        string(data.Properties.VariableNames))) && height(data) > 0;
end


function menu = assert_menu_local(fig, textValue)
    menu = findall(fig, 'Text', char(textValue));
    menu = menu(arrayfun(@(h) isa(h, 'matlab.ui.container.Menu'), menu));
    assert(~isempty(menu), ...
        'App smoke test could not find expected menu item.');
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


function assert_status_contains_local(app, token)
    labels = findall(app.UIFigure, '-isa', 'matlab.ui.control.Label');
    texts = strings(numel(labels), 1);
    for k = 1:numel(labels)
        texts(k) = string(labels(k).Text);
    end
    assert(any(contains(texts, token)), ...
        'App status did not contain "%s".', token);
end
