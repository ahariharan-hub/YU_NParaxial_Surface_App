function result = demo_nparaxial_milestone221_stabilization_yu()
%DEMO_NPARAXIAL_MILESTONE221_STABILIZATION_YU Stabilization checks.

    testFolder = fileparts(mfilename('fullpath'));
    rootFolder = fileparts(testFolder);
    addpath(rootFolder);
    addpath(fullfile(rootFolder, 'core'));

    test_extension_handling_local(testFolder);
    test_combined_report_selected_stop_local();
    test_table_serializer_local();
    appSmokeStatus = test_app_dirty_state_smoke_local(rootFolder);

    result = struct();
    result.case_name = "milestone221_stabilization";
    result.num_checks = 4;
    result.app_smoke = appSmokeStatus;
end


function test_extension_handling_local(testFolder)
    T = table;
    T.index = [1; 2];
    T.label = ["a"; "b"];

    csvBase = tempname(testFolder);
    csvFile = [csvBase, '.csv'];
    cleanupCsv = onCleanup(@() cleanup_file_local(csvFile)); %#ok<NASGU>

    actualCsv = nparaxial_export_table_csv_yu(T, csvBase);
    assert(strcmp(actualCsv, csvFile), ...
        'CSV export helper should append .csv when missing.');
    loaded = readtable(actualCsv);
    assert(isequal(loaded.index, T.index), ...
        'CSV extension test did not preserve table values.');

    txtBase = tempname(testFolder);
    txtFile = [txtBase, '.txt'];
    cleanupTxt = onCleanup(@() cleanup_file_local(txtFile)); %#ok<NASGU>

    actualTxt = nparaxial_export_summary_txt_yu( ...
        ["first line"; "second line"], txtBase);
    assert(strcmp(actualTxt, txtFile), ...
        'TXT export helper should append .txt when missing.');
    text = string(fileread(actualTxt));
    assert(contains(text, "first line") && contains(text, "second line"), ...
        'TXT extension test did not preserve report lines.');
end


function test_combined_report_selected_stop_local()
    zObj = -120;
    p = nparaxial_default_prescription_yu("two thin lenses");
    img = nparaxial_solve_image_plane_yu(p, zObj);
    diagnostics = nparaxial_field_diagnostics_yu(p, zObj, img.z_img, 3.5);

    quantity = ["A_ref"; "B_ref"; "C_ref"; "D_ref"];
    value = [img.A_ref; img.B_ref; img.C_ref; img.D_ref];
    matrixTable = table(quantity, value);

    lines = nparaxial_combined_report_yu( ...
        p, matrixTable, img, diagnostics, "summary sentinel");
    text = strjoin(string(lines), newline);

    requiredTokens = [
        "Selected axial stop"
        "selected_axial_stop_element_id ="
        "selected_axial_stop_type ="
        "selected_axial_stop_event_index ="
        "selected_axial_stop_z ="
        "selected_axial_stop_aperture_radius ="
        "Aperture stop is selected from the axial field y_obj = 0 using the tightest launch-slope interval."
        "Diagnostic field height y = 3.5"
        "Off-axis diagnostics trace rays for the selected field height, but aperture stop selection remains axial."
        "Full off-axis vignetting interval analysis is not implemented in this milestone."
        "Chief/marginal event trace"
        "Invariant samples"
        "Phase space"
        "Variables:"
        "row 1:"
        "ray_name"
        "canonical_H"
        "p="
    ];

    for k = 1:numel(requiredTokens)
        assert(contains(text, requiredTokens(k)), ...
            'Combined report missing token "%s".', requiredTokens(k));
    end
end


function test_table_serializer_local()
    T = table;
    T.name = ["long_column_name"; "second"];
    T.value = [pi; Inf];
    T.flag = [true; false];

    lines = nparaxial_table_to_text_yu(T);
    text = strjoin(lines, newline);

    assert(contains(text, "Variables: name, value, flag"), ...
        'Table serializer should include variable names.');
    assert(contains(text, "row 1:"), ...
        'Table serializer should emit row-by-row text.');
    assert(contains(text, "name=long_column_name"), ...
        'Table serializer should preserve string scalar values.');
    assert(contains(text, "flag=true"), ...
        'Table serializer should preserve logical scalar values.');
end


function status = test_app_dirty_state_smoke_local(rootFolder)
    status = "skipped";
    if ~usejava('awt')
        return
    end

    oldPath = path;
    cleanupPath = onCleanup(@() path(oldPath)); %#ok<NASGU>
    addpath(rootFolder);

    app = YU_NParaxialSurface_App_V1();
    cleanupApp = onCleanup(@() delete(app)); %#ok<NASGU>
    app.UIFigure.Visible = 'off';

    presetDropdown = findall(app.UIFigure, ...
        '-isa', 'matlab.ui.control.DropDown');
    assert(~isempty(presetDropdown), ...
        'App smoke test could not find default prescription dropdown.');
    presetDropdown(1).Value = 'Single thin lens';

    loadButton = findall(app.UIFigure, ...
        '-isa', 'matlab.ui.control.Button', 'Text', 'Load Default');
    assert(~isempty(loadButton), ...
        'App smoke test could not find Load Default button.');
    call_callback_local(loadButton(1).ButtonPushedFcn, loadButton(1));
    drawnow limitrate

    runButton = findall(app.UIFigure, ...
        '-isa', 'matlab.ui.control.Button', 'Text', 'Run Trace');
    assert(~isempty(runButton), 'App smoke test could not find Run Trace button.');
    call_callback_local(runButton(1).ButtonPushedFcn, runButton(1));
    drawnow limitrate
    assert_status_contains_local(app, "Trace complete.");

    numericFields = findall(app.UIFigure, ...
        '-isa', 'matlab.ui.control.NumericEditField');
    assert(~isempty(numericFields), ...
        'App smoke test could not find numeric edit fields.');
    numericFields(1).Value = numericFields(1).Value + 1;
    call_callback_local(numericFields(1).ValueChangedFcn, numericFields(1));
    drawnow limitrate
    assert_status_contains_local(app, ...
        "Inputs changed. Run Trace to refresh diagnostics.");

    exportButton = findall(app.UIFigure, ...
        '-isa', 'matlab.ui.control.Button', 'Text', 'Export Ray Table CSV');
    assert(~isempty(exportButton), ...
        'App smoke test could not find ray-table export button.');
    call_callback_local(exportButton(1).ButtonPushedFcn, exportButton(1));
    drawnow limitrate
    assert_status_contains_local(app, ...
        "Inputs changed. Run Trace to refresh diagnostics.");

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


function assert_status_contains_local(app, token)
    labels = findall(app.UIFigure, '-isa', 'matlab.ui.control.Label');
    texts = strings(numel(labels), 1);
    for k = 1:numel(labels)
        texts(k) = string(labels(k).Text);
    end
    assert(any(contains(texts, token)), ...
        'App status did not contain "%s".', token);
end


function cleanup_file_local(filename)
    if exist(filename, 'file')
        delete(filename);
    end
end
