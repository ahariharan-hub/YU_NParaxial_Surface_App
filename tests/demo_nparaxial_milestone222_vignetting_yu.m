function result = demo_nparaxial_milestone222_vignetting_yu()
%DEMO_NPARAXIAL_MILESTONE222_VIGNETTING_YU Vignetting interval checks.

    testFolder = fileparts(mfilename('fullpath'));
    rootFolder = fileparts(testFolder);
    addpath(fullfile(rootFolder, 'core'));

    test_stop_only_axial_local();
    test_stop_only_off_axis_local();
    test_two_apertures_different_limits_local();
    test_fully_vignetted_local();
    test_cumulative_disjoint_fully_vignetted_local();
    test_same_z_event_order_local();
    test_powered_aperture_pre_event_height_local();
    test_surface_aperture_pre_event_height_local();
    appVignettingSmoke = test_app_vignetting_tab_smoke_local(rootFolder);

    result = struct();
    result.case_name = "milestone222_vignetting";
    result.num_checks = 9;
    result.app_vignetting_smoke = appVignettingSmoke;
end


function test_stop_only_axial_local()
    p = prescription_local("STOP", 1, "stop", 100, 5, Inf, Inf);
    vig = nparaxial_vignetting_intervals_yu(p, 0, 0);

    assert_close_local(vig.u_low, -0.05, ...
        'Stop-only axial lower interval mismatch.');
    assert_close_local(vig.u_high, 0.05, ...
        'Stop-only axial upper interval mismatch.');
    assert(~vig.fully_vignetted, ...
        'Stop-only axial field should not be fully vignetted.');
    assert(vig.is_symmetric, ...
        'Stop-only axial interval should be symmetric about u0 = 0.');
end


function test_stop_only_off_axis_local()
    p = prescription_local("STOP", 1, "stop", 100, 5, Inf, Inf);
    vig = nparaxial_vignetting_intervals_yu(p, 0, 1);

    assert_close_local(vig.u_low, -0.06, ...
        'Stop-only off-axis lower interval mismatch.');
    assert_close_local(vig.u_high, 0.04, ...
        'Stop-only off-axis upper interval mismatch.');
    assert(~vig.is_symmetric, ...
        'Off-axis stop-only interval should be shifted from u0 = 0.');
    assert_close_local(vig.u_high - vig.u_low, ...
        vig.axial_u_high - vig.axial_u_low, ...
        'Stop-only off-axis interval width should match axial width.');
    assert(~vig.partially_vignetted_relative_to_axial, ...
        'A shifted stop-only interval with unchanged width is not partial vignetting.');
end


function test_two_apertures_different_limits_local()
    p = prescription_local( ...
        ["STOP1"; "L1"; "STOP2"], ...
        [1; 2; 3], ...
        ["stop"; "thinlens"; "stop"], ...
        [10; 12; 20], ...
        [0.8; Inf; 1.0], ...
        [Inf; 10; Inf], ...
        [Inf; Inf; Inf]);

    vig = nparaxial_vignetting_intervals_yu(p, 0, 2);

    assert(~vig.fully_vignetted, ...
        'Constructed two-aperture case should leave a finite interval.');
    assert(vig.lower_bound_element_id ~= vig.upper_bound_element_id, ...
        'Lower and upper limiting apertures should differ.');
    assert(vig.lower_bound_element_id == "STOP2", ...
        'Expected STOP2 to set the lower launch-slope bound.');
    assert(vig.upper_bound_element_id == "STOP1", ...
        'Expected STOP1 to set the upper launch-slope bound.');
    assert(vig.partially_vignetted_relative_to_axial, ...
        'Two-aperture off-axis case should be partially vignetted relative to axial.');
end


function test_fully_vignetted_local()
    p = prescription_local("STOP", 1, "stop", 0, 5, Inf, Inf);
    vig = nparaxial_vignetting_intervals_yu(p, 0, 10);
    summary = nparaxial_vignetting_summary_yu(vig);
    summaryText = strjoin(string(summary.lines), newline);

    assert(vig.fully_vignetted, ...
        'Field should be fully vignetted by an object-plane stop.');
    assert(vig.u_low > vig.u_high, ...
        'Fully vignetted interval should be empty.');
    assert(contains(summaryText, "empty"), ...
        'Fully vignetted summary should say the final interval is empty.');
    assert(~contains(summaryText, "[Inf, -Inf]"), ...
        'Fully vignetted summary should not display [Inf, -Inf].');
end


function test_cumulative_disjoint_fully_vignetted_local()
    p = prescription_local( ...
        ["STOP1"; "STOP2"], [1; 2], ["stop"; "stop"], ...
        [10; 20], [0.5; 0.5], [Inf; Inf], [Inf; Inf]);
    vig = nparaxial_vignetting_intervals_yu(p, 0, 2);

    assert(all(~vig.candidate_table.interval_empty), ...
        'Each individual aperture interval should be nonempty.');
    assert(vig.fully_vignetted, ...
        'Disjoint cumulative aperture intervals should fully vignette the field.');
    assert(vig.u_low > vig.u_high, ...
        'Disjoint cumulative interval should be empty.');
    assert(vig.lower_bound_element_id ~= vig.upper_bound_element_id, ...
        'Disjoint interval lower and upper bounds should come from different apertures.');
end


function test_same_z_event_order_local()
    p = prescription_local( ...
        ["WIDE"; "NARROW"], [2; 1], ["stop"; "stop"], ...
        [25; 25], [10; 2], [Inf; Inf], [Inf; Inf]);
    vig = nparaxial_vignetting_intervals_yu(p, 0, 0);

    assert(vig.candidate_table.element_id(1) == "NARROW", ...
        'Same-z vignetting candidates should respect event_order.');
    assert(vig.candidate_table.element_id(2) == "WIDE", ...
        'Same-z vignetting candidates should preserve sorted event order.');
end


function test_powered_aperture_pre_event_height_local()
    p = prescription_local("L1", 1, "thinlens", 10, 5, 2, Inf);
    vig = nparaxial_vignetting_intervals_yu(p, 0, 1);

    assert_close_local(vig.u_low, -0.6, ...
        'Powered aperture lower bound should use pre-event height.');
    assert_close_local(vig.u_high, 0.4, ...
        'Powered aperture upper bound should use pre-event height.');
end


function test_surface_aperture_pre_event_height_local()
    p = prescription_with_media_local("S1", 1, "surface", 10, 5, Inf, 20, 1, 1.5);
    vig = nparaxial_vignetting_intervals_yu(p, 0, 1);

    assert_close_local(vig.candidate_table.A_to_aperture(1), 1, ...
        'Surface aperture should use pre-event A coefficient.');
    assert_close_local(vig.candidate_table.B_to_aperture(1), 10, ...
        'Surface aperture should use pre-event B coefficient.');
    assert_close_local(vig.u_low, -0.6, ...
        'Surface aperture lower bound should use pre-event height.');
    assert_close_local(vig.u_high, 0.4, ...
        'Surface aperture upper bound should use pre-event height.');
end


function p = prescription_local(elementId, eventOrder, typeName, z, aperture, f, R)
    n = numel(string(elementId));
    p = table;
    p.element_id = string(elementId(:));
    p.event_order = expand_double_local(eventOrder, n);
    p.type = string(typeName(:));
    p.z = expand_double_local(z, n);
    p.aperture_radius = expand_double_local(aperture, n);
    p.focal_length = expand_double_local(f, n);
    p.radius_R = expand_double_local(R, n);
    p.n_before = ones(n, 1);
    p.n_after = ones(n, 1);
    p.enabled = true(n, 1);
    p = nparaxial_validate_prescription_yu(p);
end


function p = prescription_with_media_local( ...
    elementId, eventOrder, typeName, z, aperture, f, R, nBefore, nAfter)

    p = prescription_local(elementId, eventOrder, typeName, z, aperture, f, R);
    p.n_before = expand_double_local(nBefore, height(p));
    p.n_after = expand_double_local(nAfter, height(p));
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


function status = test_app_vignetting_tab_smoke_local(rootFolder)
    status = "skipped";
    if ~usejava('awt')
        return
    end

    addpath(rootFolder);
    addpath(fullfile(rootFolder, 'core'));

    app = YU_NParaxialSurface_App_V1();
    cleanupApp = onCleanup(@() delete(app)); %#ok<NASGU>
    app.UIFigure.Visible = 'off';

    presetDropdown = findall(app.UIFigure, ...
        '-isa', 'matlab.ui.control.DropDown');
    presetDropdown(1).Value = 'Single thin lens';
    loadButton = findall(app.UIFigure, ...
        '-isa', 'matlab.ui.control.Button', 'Text', 'Load Default');
    call_callback_local(loadButton(1).ButtonPushedFcn, loadButton(1));

    runButton = findall(app.UIFigure, ...
        '-isa', 'matlab.ui.control.Button', 'Text', 'Run Trace');
    call_callback_local(runButton(1).ButtonPushedFcn, runButton(1));
    drawnow limitrate

    vignettingTab = findall(app.UIFigure, ...
        '-isa', 'matlab.ui.container.Tab', 'Title', 'Vignetting');
    assert(~isempty(vignettingTab), ...
        'App smoke test could not find the Vignetting tab.');
    vignettingTab(1).Parent.SelectedTab = vignettingTab(1);
    tabGroup = findall(app.UIFigure, '-isa', 'matlab.ui.container.TabGroup');
    if ~isempty(tabGroup) && ~isempty(tabGroup(1).SelectionChangedFcn)
        call_callback_local(tabGroup(1).SelectionChangedFcn, tabGroup(1));
    end
    drawnow limitrate

    tables = findall(app.UIFigure, '-isa', 'matlab.ui.control.Table');
    foundVignettingTable = false;
    for k = 1:numel(tables)
        T = tables(k).Data;
        if istable(T) && ismember('u_low', T.Properties.VariableNames)
            foundVignettingTable = true;
            break
        end
    end
    assert(foundVignettingTable, ...
        'Vignetting tab did not populate an interval table after Run Trace.');

    status = "passed";
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
