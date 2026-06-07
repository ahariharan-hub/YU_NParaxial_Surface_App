function results = demo_nparaxial_milestone263_classical_default_cases_yu()
%DEMO_NPARAXIAL_MILESTONE263_CLASSICAL_DEFAULT_CASES_YU Case library checks.

    testFolder = fileparts(mfilename('fullpath'));
    rootFolder = fileparts(testFolder);
    addpath(rootFolder);
    addpath(fullfile(rootFolder, 'core'));
    addpath(fullfile(rootFolder, 'workflows'));
    addpath(fullfile(rootFolder, 'plotting'));

    numChecks = 0;
    cases = nparaxial_default_case_library_yu();
    assert(~isempty(cases), 'Default case library should return cases.');
    numChecks = numChecks + 1;

    keys = string({cases.key}).';
    assert(numel(keys) == numel(unique(keys)), ...
        'Default case keys should be unique.');
    numChecks = numChecks + 1;

    requiredFields = [
        "name"
        "key"
        "family"
        "description"
        "object_conjugate"
        "object_z"
        "launch_z"
        "prescription"
        "field_mode"
        "field_y"
        "field_min_y"
        "field_max_y"
        "field_count"
        "ray_fan_mode"
        "n_rays"
        "u_max"
        "source_mode"
        "expected_behavior"
        "teaching_point"
        ];
    assert(all(isfield(cases, cellstr(requiredFields))), ...
        'Every case should expose required metadata fields.');
    numChecks = numChecks + 1;

    finiteMask = string({cases.object_conjugate}).' == "finite";
    infinityMask = string({cases.object_conjugate}).' == "infinity";
    finiteObjectZ = arrayfun(@(c) c.object_z, cases(finiteMask)).';
    finiteLaunchZ = arrayfun(@(c) c.launch_z, cases(finiteMask)).';
    assert(all(finiteObjectZ == 0) && ...
        all(isfinite(finiteLaunchZ) & finiteLaunchZ == 0), ...
        'Finite-conjugate cases should use object_z=0 and launch_z=0.');
    numChecks = numChecks + 1;

    infinityObjectZ = arrayfun(@(c) c.object_z, cases(infinityMask)).';
    infinityLaunchZ = arrayfun(@(c) c.launch_z, cases(infinityMask)).';
    assert(all(isinf(infinityObjectZ)) && all(isfinite(infinityLaunchZ)), ...
        'Infinity cases should use object_z=Inf metadata and finite launch_z.');
    numChecks = numChecks + 1;

    for k = 1:numel(cases)
        p = nparaxial_validate_prescription_yu(cases(k).prescription);
        zEnabled = p.z(p.enabled);
        assert(all(zEnabled > cases(k).launch_z), ...
            'All enabled elements should be after launch_z for %s.', ...
            cases(k).key);
    end
    numChecks = numChecks + 1;

    for k = 1:numel(cases)
        nparaxial_validate_prescription_yu(cases(k).prescription);
    end
    numChecks = numChecks + 1;

    legacyDefault = nparaxial_default_prescription_yu();
    legacyTwo = nparaxial_default_prescription_yu("two thin lenses");
    legacyStop = nparaxial_default_prescription_yu("stop clipping demo");
    legacyFree = nparaxial_default_prescription_yu( ...
        "Homogeneous translation / free-space propagation");
    assert(height(nparaxial_validate_prescription_yu(legacyDefault)) == 3 && ...
        height(nparaxial_validate_prescription_yu(legacyTwo)) == 3 && ...
        height(nparaxial_validate_prescription_yu(legacyStop)) == 4 && ...
        height(nparaxial_validate_prescription_yu(legacyFree)) == 1, ...
        'Backward-compatible default prescriptions should still work.');
    numChecks = numChecks + 4;

    newDefault = nparaxial_get_default_case_yu();
    assert(newDefault.key == "basic_single_lens_m_minus_0p5", ...
        'Structured default case should be the finite single-lens example.');
    fromDefaultHelper = nparaxial_default_prescription_yu(newDefault.key);
    assert_prescriptions_equal_local(fromDefaultHelper, newDefault.prescription);
    numChecks = numChecks + 2;

    expected = expected_value_checks_local();
    numChecks = numChecks + expected.num_checks;

    v2File = fullfile(rootFolder, 'YU_NParaxialSurface_App_V2.m');
    sourceText = string(fileread(v2File));
    assert(~contains(sourceText, 'nparaxial_paraxial_validity_yu') && ...
        ~contains(sourceText, 'nparaxial_validity_field_sweep_yu'), ...
        'V2 source should not call validity or field-sweep diagnostics.');
    assert(contains(sourceText, 'nparaxial_make_collimated_rays_yu'), ...
        'V2 should use finite collimated rays for infinity cases.');
    numChecks = numChecks + 3;

    [v2Smoke, v2Checks, representativeRuns] = v2_case_smoke_local(rootFolder);
    numChecks = numChecks + v2Checks;

    [v1Smoke, v1Checks] = v1_smoke_local(rootFolder);
    numChecks = numChecks + v1Checks;

    results = struct();
    results.case_name = "milestone263_classical_default_cases";
    results.num_checks = numChecks;
    results.case_count = numel(cases);
    results.v2_smoke = v2Smoke;
    results.v1_smoke = v1Smoke;
    results.default_case = newDefault.display_name;
    results.expected_values = expected;
    results.representative_v2_runs = representativeRuns;
end


function expected = expected_value_checks_local()
    numChecks = 0;

    img = image_for_case_local("basic_single_lens_m_minus_0p5");
    assert_close_local(img.z_img, 450, 'single lens m=-0.5 z image');
    assert_close_local(img.m, -0.5, 'single lens m=-0.5 magnification');
    numChecks = numChecks + 2;

    img = image_for_case_local("basic_single_lens_1to1");
    assert_close_local(img.z_img, 400, 'single lens 1:1 z image');
    numChecks = numChecks + 1;

    img = image_for_case_local("relay_4f_1to1");
    assert_close_local(img.z_img, 400, '4f relay 1:1 z image');
    numChecks = numChecks + 1;

    img = image_for_case_local("relay_4f_reducer_m_minus_0p5");
    assert_close_local(img.m, -0.5, '4f reducer magnification');
    numChecks = numChecks + 1;

    img = image_for_case_local("relay_4f_magnifier_m_minus_2");
    assert_close_local(img.m, -2, '4f magnifier magnification');
    numChecks = numChecks + 1;

    [C, D] = afocal_cd_local("afocal_keplerian_telescope");
    assert_close_local(C, 0, 'Keplerian C');
    assert_close_local(D, -2, 'Keplerian angular magnification');
    numChecks = numChecks + 2;

    [C, D] = afocal_cd_local("afocal_galilean_telescope");
    assert_close_local(C, 0, 'Galilean C');
    assert_close_local(D, 2, 'Galilean angular magnification');
    numChecks = numChecks + 2;

    expected = struct();
    expected.num_checks = numChecks;
    expected.single_lens_m_minus_0p5_z = 450;
    expected.single_lens_1to1_z = 400;
    expected.relay_4f_1to1_z = 400;
    expected.relay_4f_reducer_m = -0.5;
    expected.relay_4f_magnifier_m = -2;
    expected.keplerian_C = 0;
    expected.keplerian_D = -2;
    expected.galilean_C = 0;
    expected.galilean_D = 2;
end


function img = image_for_case_local(key)
    caseDef = nparaxial_get_default_case_yu(key);
    img = nparaxial_solve_image_plane_yu( ...
        caseDef.prescription, caseDef.launch_z, 1e-12);
end


function [C, D] = afocal_cd_local(key)
    caseDef = nparaxial_get_default_case_yu(key);
    elements = nparaxial_enabled_elements_yu(caseDef.prescription);
    M = nparaxial_system_matrix_yu( ...
        caseDef.prescription, caseDef.launch_z, max(elements.z));
    C = M(2, 1);
    D = M(2, 2);
end


function [status, numChecks, representativeRuns] = v2_case_smoke_local(rootFolder)
    status = "skipped";
    numChecks = 0;
    representativeRuns = table(strings(0, 1), zeros(0, 1), ...
        'VariableNames', {'case_label', 'run_trace_s'});
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
    assert(numel(tabGroup.Children) == 5, ...
        'V2 should remain a five-tab lightweight viewer.');
    numChecks = numChecks + 1;

    presetDropdown = find_by_tag_local(app.UIFigure, ...
        'matlab.ui.control.DropDown', 'nparaxial_v2_preset');
    loadDefaultButton = find_by_tag_local(app.UIFigure, ...
        'matlab.ui.control.Button', 'nparaxial_v2_load_default');
    runButton = find_by_tag_local(app.UIFigure, ...
        'matlab.ui.control.Button', 'nparaxial_v2_run_trace');
    timingLabel = find_by_tag_local(app.UIFigure, ...
        'matlab.ui.control.Label', 'nparaxial_v2_timing_label');
    prescriptionTable = find_by_tag_local(app.UIFigure, ...
        'matlab.ui.control.Table', 'nparaxial_v2_prescription_table');
    objectZ = find_by_tag_local(app.UIFigure, ...
        'matlab.ui.control.NumericEditField', 'nparaxial_v2_object_z');

    defaultCase = nparaxial_get_default_case_yu();
    assert(string(presetDropdown.Value) == string(defaultCase.display_name), ...
        'V2 should load the new structured default case.');
    assert_prescriptions_equal_local(prescriptionTable.Data, ...
        defaultCase.prescription);
    numChecks = numChecks + 2;

    call_callback_local(runButton.ButtonPushedFcn, runButton);
    drawnow limitrate
    seconds = parse_run_time_local(timingLabel.Text);
    assert(isfinite(seconds) && seconds >= 0, ...
        'V2 structured default Run Trace should complete.');
    numChecks = numChecks + 1;

    caseKeys = [
        "basic_single_lens_m_minus_0p5"
        "relay_4f_1to1"
        "afocal_keplerian_telescope"
        "thick_biconvex"
        "debug_stop_clipping_demo"
        ];
    for k = 1:numel(caseKeys)
        caseDef = nparaxial_get_default_case_yu(caseKeys(k));
        presetDropdown.Value = char(caseDef.display_name);
        call_callback_local(loadDefaultButton.ButtonPushedFcn, ...
            loadDefaultButton);
        assert_prescriptions_equal_local(prescriptionTable.Data, ...
            caseDef.prescription);
        assert(isfinite(objectZ.Value) && ...
            abs(objectZ.Value - caseDef.launch_z) < 1e-12, ...
            'V2 should use finite launch_z for %s.', caseDef.key);
        call_callback_local(runButton.ButtonPushedFcn, runButton);
        drawnow limitrate
        seconds = parse_run_time_local(timingLabel.Text);
        assert(isfinite(seconds) && seconds >= 0, ...
            'V2 case %s should run.', caseDef.key);
        representativeRuns(end+1, :) = { ...
            string(caseDef.display_name), seconds}; %#ok<AGROW>
        numChecks = numChecks + 3;
    end

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


function seconds = parse_run_time_local(textValue)
    token = regexp(char(textValue), '([0-9.]+)\s*s', 'tokens', 'once');
    if isempty(token)
        seconds = NaN;
    else
        seconds = str2double(token{1});
    end
end


function assert_prescriptions_equal_local(actual, expected)
    actual = table_to_prescription_yu(actual);
    expected = table_to_prescription_yu(expected);
    assert(isequaln(actual, expected), ...
        'Prescription tables should match.');
end


function assert_close_local(actual, expected, label)
    assert(abs(double(actual) - double(expected)) < 1e-9, ...
        '%s expected %.12g, got %.12g.', label, expected, actual);
end
