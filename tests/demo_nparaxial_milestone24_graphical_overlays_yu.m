function results = demo_nparaxial_milestone24_graphical_overlays_yu()
%DEMO_NPARAXIAL_MILESTONE24_GRAPHICAL_OVERLAYS_YU Plot-helper tests.

    testFolder = fileparts(mfilename('fullpath'));
    rootFolder = fileparts(testFolder);
    addpath(rootFolder);
    addpath(fullfile(rootFolder, 'core'));

    numChecks = 0;

    test_surface_curve_positive_radius_local();
    numChecks = numChecks + 1;

    test_surface_curve_negative_radius_local();
    numChecks = numChecks + 1;

    test_plane_surface_curve_local();
    numChecks = numChecks + 1;

    test_first_segment_penalty_signs_local();
    numChecks = numChecks + 1;

    test_zero_first_segment_distance_local();
    numChecks = numChecks + 1;

    test_surface_angle_schematic_local();
    numChecks = numChecks + 1;

    appSmoke = app_smoke_local(rootFolder);
    if appSmoke == "passed"
        numChecks = numChecks + 1;
    end

    results = struct();
    results.case_name = "milestone24_graphical_overlays";
    results.num_checks = numChecks;
    results.app_smoke = appSmoke;
end


function test_surface_curve_positive_radius_local()
    zVertex = 10;
    [zCurve, yCurve, info] = nparaxial_surface_curve_points_yu( ...
        zVertex, 100, 20, 30, 51, 1e-12);
    nonzero = abs(yCurve) > 0;

    assert(info.is_finite_surface, ...
        'Finite R > 0 should be identified as finite spherical surface.');
    assert(any(zCurve(nonzero) > zVertex), ...
        'R > 0 curve sag should move to larger z away from the vertex.');
end


function test_surface_curve_negative_radius_local()
    zVertex = 10;
    [zCurve, yCurve, info] = nparaxial_surface_curve_points_yu( ...
        zVertex, -100, 20, 30, 51, 1e-12);
    nonzero = abs(yCurve) > 0;

    assert(info.is_finite_surface, ...
        'Finite R < 0 should be identified as finite spherical surface.');
    assert(any(zCurve(nonzero) < zVertex), ...
        'R < 0 curve sag should move to smaller z away from the vertex.');
end


function test_plane_surface_curve_local()
    [zCurve, ~, info] = nparaxial_surface_curve_points_yu( ...
        5, Inf, Inf, 12, 9, 1e-12);

    assert(~info.is_finite_surface, ...
        'R = Inf should be identified as a plane/vertical representation.');
    assert(all(zCurve == 5), ...
        'Plane surface representation should be vertical at zVertex.');
    assert(info.used_fallback_height, ...
        'Plane surface with infinite aperture should use visual fallback height.');
end


function test_first_segment_penalty_signs_local()
    rays = ray_table_local(["pos"; "neg"], [0; 0], [0; 0], [0.1; -0.1]);
    overlay = nparaxial_first_segment_penalty_overlay_yu(rays, 0, 10, 1e-12);
    expected = 10*(tan(rays.u0) - rays.u0);

    assert(all(overlay.valid_overlay), ...
        'Finite first segment and finite tan(u0) should create valid overlays.');
    assert_close_local(overlay.delta_y_first_segment, expected, ...
        'First-segment delta_y should equal d*(tan(u0)-u0).');
    assert(overlay.delta_y_first_segment(1) > 0 && ...
        overlay.delta_y_first_segment(2) < 0, ...
        'First-segment penalty sign should follow u sign.');
end


function test_zero_first_segment_distance_local()
    rays = ray_table_local("zero_d", 0, 1, 0.1);
    overlay = nparaxial_first_segment_penalty_overlay_yu(rays, 0, 0, 1e-12);

    assert(~overlay.valid_overlay(1), ...
        'Zero first-segment distance should skip the overlay.');
    assert(overlay.delta_y_first_segment(1) == 0, ...
        'Zero first-segment distance should report zero penalty.');
    assert(contains(overlay.note(1), "distance is zero"), ...
        'Zero-distance overlay should include a clear note.');
end


function test_surface_angle_schematic_local()
    y = 5;
    u = 0.1;
    R = 100;
    schematic = nparaxial_surface_angle_schematic_yu(y, u, R, 1e-12);
    expectedAlpha = -asin(y/R);
    expectedTheta = u - expectedAlpha;

    assert(schematic.valid_schematic(1), ...
        'Finite y/R within range should produce a valid schematic.');
    assert_close_local(schematic.alpha(1), expectedAlpha, ...
        'Surface-angle schematic should use alpha = -asin(y/R).');
    assert_close_local(schematic.theta(1), expectedTheta, ...
        'Surface-angle schematic should use theta = u - alpha.');
    assert_close_local(schematic.u_deg(1), u*180/pi, ...
        'u_deg should convert the paraxial angle from radians to degrees.');
    assert_close_local(schematic.theta_deg(1), expectedTheta*180/pi, ...
        'theta_deg should convert incidence angle from radians to degrees.');
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

    status = "not_applicable_public_v2_tree";
    return
    cleanupApp = onCleanup(@() delete(app)); %#ok<NASGU>
    app.UIFigure.Visible = 'off';

    surfaceCurves = find_checkbox_local(app.UIFigure, "Surface curves");
    penalty = find_checkbox_local(app.UIFigure, "First-segment penalty");
    schematic = find_checkbox_local(app.UIFigure, "Surface-angle schematic");
    assert(surfaceCurves.Value, ...
        'Surface curve overlay should default ON.');
    assert(~penalty.Value && ~schematic.Value, ...
        'Penalty and schematic overlays should default OFF.');

    presetDropdown = find_dropdown_with_item_local(app.UIFigure, "Single thin lens");
    presetDropdown.Value = 'Single thin lens';
    presetButton = findall(app.UIFigure, ...
        '-isa', 'matlab.ui.control.Button', 'Text', 'Load Default');
    assert(~isempty(presetButton), ...
        'App smoke test could not find Load Default button.');
    call_callback_local(presetButton(1).ButtonPushedFcn, presetButton(1));
    drawnow limitrate

    runButton = findall(app.UIFigure, ...
        '-isa', 'matlab.ui.control.Button', 'Text', 'Run Trace');
    assert(~isempty(runButton), ...
        'App smoke test could not find Run Trace button.');
    call_callback_local(runButton(1).ButtonPushedFcn, runButton(1));
    drawnow limitrate

    penalty.Value = true;
    call_callback_local(penalty.ValueChangedFcn, penalty);
    drawnow limitrate
    assert_status_contains_local(app, "Ray diagram overlay display refreshed.");
    assert_status_not_contains_local(app, ...
        "Inputs changed. Run Trace to refresh diagnostics.");

    schematic.Value = true;
    call_callback_local(schematic.ValueChangedFcn, schematic);
    drawnow limitrate
    assert_status_contains_local(app, "Ray diagram overlay display refreshed.");
    assert_status_not_contains_local(app, ...
        "Inputs changed. Run Trace to refresh diagnostics.");

    status = "passed";
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
        if string(checkboxes(k).Text) == textValue
            checkbox = checkboxes(k);
            return
        end
    end
    error('Could not find checkbox "%s".', textValue);
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


function assert_status_not_contains_local(app, token)
    labels = findall(app.UIFigure, '-isa', 'matlab.ui.control.Label');
    texts = strings(numel(labels), 1);
    for k = 1:numel(labels)
        texts(k) = string(labels(k).Text);
    end
    assert(~any(contains(texts, token)), ...
        'App status unexpectedly contained "%s".', token);
end


function rays = ray_table_local(name, z0, y0, u0)
    rays = table;
    rays.name = string(name(:));
    rays.z0 = double(z0(:));
    rays.y0 = double(y0(:));
    rays.u0 = double(u0(:));
end


function assert_close_local(actual, expected, message)
    actual = double(actual(:));
    expected = double(expected(:));
    assert(isequal(size(actual), size(expected)), ...
        'Arrays have different sizes.');
    assert(max(abs(actual - expected)) < 1e-12, message);
end
