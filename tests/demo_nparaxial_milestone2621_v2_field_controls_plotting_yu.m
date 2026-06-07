function results = demo_nparaxial_milestone2621_v2_field_controls_plotting_yu()
%DEMO_NPARAXIAL_MILESTONE2621_V2_FIELD_CONTROLS_PLOTTING_YU V2 field/plot checks.

    testFolder = fileparts(mfilename('fullpath'));
    rootFolder = fileparts(testFolder);
    addpath(rootFolder);
    addpath(fullfile(rootFolder, 'core'));
    addpath(fullfile(rootFolder, 'workflows'));
    addpath(fullfile(rootFolder, 'plotting'));

    numChecks = 0;
    plottingFolder = fullfile(rootFolder, 'plotting');
    movedHelpers = [
        "nparaxial_plot_cardinal_points_yu.m"
        "nparaxial_clear_cardinal_points_yu.m"
        "nparaxial_ray_role_style_yu.m"
        "nparaxial_legend_unique_yu.m"
        ];
    assert(isfolder(plottingFolder) && ...
        isfile(fullfile(plottingFolder, 'viridis.m')) && ...
        isfile(fullfile(plottingFolder, 'nparaxial_grating_order_style_yu.m')), ...
        'plotting folder should contain viridis and grating order styling.');
    for k = 1:numel(movedHelpers)
        assert(isfile(fullfile(plottingFolder, movedHelpers(k))) && ...
            ~isfile(fullfile(rootFolder, 'core', movedHelpers(k))), ...
            'Plotting helper %s should be moved out of core.', movedHelpers(k));
    end
    numChecks = numChecks + 1 + numel(movedHelpers);

    v2File = fullfile(rootFolder, 'YU_NParaxialSurface_App_V2.m');
    sourceText = string(fileread(v2File));
    assert(contains(sourceText, 'nparaxial_grating_order_style_yu') && ...
        ~contains(sourceText, 'nparaxial_paraxial_validity_yu') && ...
        ~contains(sourceText, 'nparaxial_validity_field_sweep_yu'), ...
        'V2 should use order styling and avoid heavy validity helpers.');
    numChecks = numChecks + 3;

    colorChecks = grating_color_style_checks_local();
    numChecks = numChecks + colorChecks;

    [appSmoke, appChecks, pointSeconds, gratingSeconds] = ...
        v2_field_plotting_smoke_local(rootFolder);
    numChecks = numChecks + appChecks;

    results = struct();
    results.case_name = "milestone2621_v2_field_controls_plotting";
    results.num_checks = numChecks;
    results.app_smoke = appSmoke;
    results.point_run_trace_s = pointSeconds;
    results.grating_run_trace_s = gratingSeconds;
end


function numChecks = grating_color_style_checks_local()
    numChecks = 0;
    orders = (-2:2).';
    styles = nparaxial_grating_order_style_yu( ...
        orders, false(numel(orders), 1), orders);
    zeroIdx = find(orders == 0, 1);
    assert_color_local(styles.color(zeroIdx, :), [0 0 0], ...
        'm = 0 grating order should be black.');
    assert(styles.line_width(zeroIdx) > max(styles.line_width(orders ~= 0)), ...
        'm = 0 grating order should be slightly thicker.');
    numChecks = numChecks + 2;

    colorsByOrder = containers.Map('KeyType', 'double', 'ValueType', 'any');
    for k = 1:numel(orders)
        colorsByOrder(orders(k)) = styles.color(k, :);
    end
    assert_color_not_equal_local(colorsByOrder(-1), colorsByOrder(1), ...
        'Positive and negative first orders should be distinct.');
    assert_color_not_equal_local(colorsByOrder(-2), colorsByOrder(2), ...
        'Positive and negative boundary orders should be distinct.');
    midApprox = 0.5*(colorsByOrder(-1) + colorsByOrder(1));
    assert(norm(colorsByOrder(-1) - midApprox) < ...
        norm(colorsByOrder(-2) - midApprox) && ...
        norm(colorsByOrder(1) - midApprox) < ...
        norm(colorsByOrder(2) - midApprox), ...
        'Lower-magnitude nonzero orders should blend toward the center.');
    assert(all(styles.display_name == ...
        ["m = -2"; "m = -1"; "m = 0"; "m = +1"; "m = +2"]), ...
        'Order display names should be stable and signed.');
    stableStyles = nparaxial_grating_order_style_yu( ...
        [-2; 0; 2], false(3, 1), orders);
    assert_color_local(stableStyles.color(1, :), colorsByOrder(-2), ...
        'Missing orders should not shift negative order colors.');
    assert_color_local(stableStyles.color(2, :), [0 0 0], ...
        'Missing orders should not affect m = 0 black.');
    assert_color_local(stableStyles.color(3, :), colorsByOrder(2), ...
        'Missing orders should not shift positive order colors.');
    numChecks = numChecks + 4;
end


function [status, numChecks, pointSeconds, gratingSeconds] = ...
    v2_field_plotting_smoke_local(rootFolder)

    status = "skipped";
    numChecks = 0;
    pointSeconds = NaN;
    gratingSeconds = NaN;
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
    tabTitles = string({tabGroup.Children.Title}).';
    expectedTabs = [
        "Ray Diagram"
        "System Matrix"
        "Cardinal/Gaussian"
        "Stop/Pupils"
        "Equations"
        ];
    assert(numel(tabTitles) == 5 && all(ismember(expectedTabs, tabTitles)), ...
        'V2 should remain a five-tab lightweight viewer.');
    numChecks = numChecks + 1;

    assert_no_x_field_controls_local(app.UIFigure);
    numChecks = numChecks + 1;

    objectType = find_by_tag_local(app.UIFigure, ...
        'matlab.ui.control.DropDown', 'nparaxial_v2_object_type');
    fieldMode = find_by_tag_local(app.UIFigure, ...
        'matlab.ui.control.DropDown', 'nparaxial_v2_field_mode');
    fieldY = find_by_tag_local(app.UIFigure, ...
        'matlab.ui.control.NumericEditField', 'nparaxial_v2_field_height');
    fieldMin = find_by_tag_local(app.UIFigure, ...
        'matlab.ui.control.NumericEditField', 'nparaxial_v2_field_min_y');
    fieldMax = find_by_tag_local(app.UIFigure, ...
        'matlab.ui.control.NumericEditField', 'nparaxial_v2_field_max_y');
    fieldCount = find_by_tag_local(app.UIFigure, ...
        'matlab.ui.control.NumericEditField', 'nparaxial_v2_field_count');
    runButton = find_by_tag_local(app.UIFigure, ...
        'matlab.ui.control.Button', 'nparaxial_v2_run_trace');
    timingLabel = find_by_tag_local(app.UIFigure, ...
        'matlab.ui.control.Label', 'nparaxial_v2_timing_label');
    rayAxes = find_by_tag_local(app.UIFigure, ...
        'matlab.ui.control.UIAxes', 'nparaxial_v2_ray_axes');
    objectZ = find_by_tag_local(app.UIFigure, ...
        'matlab.ui.control.NumericEditField', 'nparaxial_v2_object_z');
    prescriptionTable = find_by_tag_local(app.UIFigure, ...
        'matlab.ui.control.Table', 'nparaxial_v2_prescription_table');
    rayFanMode = find_by_tag_local(app.UIFigure, ...
        'matlab.ui.control.DropDown', 'nparaxial_v2_fan_mode');
    labelStyle = find_by_tag_local(app.UIFigure, ...
        'matlab.ui.control.DropDown', 'nparaxial_v2_element_label_style');
    ordersField = find_by_tag_local(app.UIFigure, ...
        'matlab.ui.control.EditField', 'nparaxial_v2_grating_orders');
    rayControlsPanel = find_by_tag_local(app.UIFigure, ...
        'matlab.ui.container.Panel', ...
        'nparaxial_v2_ray_fan_prescription_panel');
    mainGrid = find_by_tag_local(app.UIFigure, ...
        'matlab.ui.container.GridLayout', 'nparaxial_v2_main_grid');
    controlGrid = find_by_tag_local(app.UIFigure, ...
        'matlab.ui.container.GridLayout', 'nparaxial_v2_control_grid');
    rayGrid = find_by_tag_local(app.UIFigure, ...
        'matlab.ui.container.GridLayout', 'nparaxial_v2_ray_grid');
    rayTopGrid = find_by_tag_local(app.UIFigure, ...
        'matlab.ui.container.GridLayout', 'nparaxial_v2_ray_top_grid');
    prescriptionButtonGrid = find_by_tag_local(app.UIFigure, ...
        'matlab.ui.container.GridLayout', ...
        'nparaxial_v2_prescription_button_grid');

    drawnow limitrate
    assert_layout_dimensions_local( ...
        mainGrid, controlGrid, rayGrid, rayTopGrid, ...
        prescriptionButtonGrid);
    assert(isvalid(objectType) && isvalid(fieldMode) && ...
        isvalid(rayFanMode) && isvalid(labelStyle) && ...
        isvalid(ordersField), ...
        'Key V2 controls should exist.');
    assert_no_duplicate_action_buttons_local(rayControlsPanel);
    assert_prescription_edit_buttons_local(rayControlsPanel);
    assert_file_menu_prescription_actions_local(app.UIFigure);
    numChecks = numChecks + 4;

    assert(all(ismember(["Single field y", "Y field sweep"], ...
        string(fieldMode.Items))) && ...
        string(fieldMode.Value) == "Single field y", ...
        'V2 should expose Single field y and Y field sweep modes.');
    numChecks = numChecks + 1;

    objectType.Value = 'Point object';
    call_callback_local(objectType.ValueChangedFcn, objectType);
    fieldMode.Value = 'Single field y';
    call_callback_local(fieldMode.ValueChangedFcn, fieldMode);
    fieldY.Value = 1.25;
    call_callback_local(fieldY.ValueChangedFcn, fieldY);
    call_callback_local(runButton.ButtonPushedFcn, runButton);
    drawnow limitrate
    pointSeconds = parse_run_time_local(timingLabel.Text);
    pointLaunchYs = launch_y_values_local(rayAxes, objectZ.Value, ...
        ["UMR", "CR", "LMR", "Intermediate"]);
    assert(isfinite(pointSeconds) && pointSeconds >= 0 && ...
        any_close_local(pointLaunchYs, 1.25), ...
        'Single field point mode should run from the selected y field.');
    numChecks = numChecks + 2;

    [ioChecks, originalPrescription] = prescription_io_checks_local( ...
        app, prescriptionTable);
    numChecks = numChecks + ioChecks;

    fieldMode.Value = 'Y field sweep';
    call_callback_local(fieldMode.ValueChangedFcn, fieldMode);
    fieldMin.Value = -2;
    fieldMax.Value = 2;
    fieldCount.Value = 3;
    call_callback_local(fieldMin.ValueChangedFcn, fieldMin);
    call_callback_local(fieldMax.ValueChangedFcn, fieldMax);
    call_callback_local(fieldCount.ValueChangedFcn, fieldCount);
    call_callback_local(runButton.ButtonPushedFcn, runButton);
    drawnow limitrate
    pointLaunchYs = launch_y_values_local(rayAxes, objectZ.Value, ...
        ["UMR", "CR", "LMR", "Intermediate"]);
    assert(all(arrayfun(@(v) any_close_local(pointLaunchYs, v), [-2 0 2])), ...
        'Point mode should trace all selected y-field sweep heights.');
    numChecks = numChecks + 1;

    showLabels = find_by_tag_local(app.UIFigure, ...
        'matlab.ui.control.CheckBox', 'nparaxial_v2_show_element_labels');
    showLabels.Value = true;
    labelStyle.Value = 'Compact';
    call_callback_local(showLabels.ValueChangedFcn, showLabels);
    call_callback_local(labelStyle.ValueChangedFcn, labelStyle);
    call_callback_local(runButton.ButtonPushedFcn, runButton);
    drawnow limitrate
    compactLabels = element_label_strings_local(rayAxes);
    assert(~isempty(compactLabels) && ...
        ~any(contains(compactLabels, "(")) && ...
        ~any(contains(compactLabels, ")")) && ...
        ~any(contains(compactLabels, " ")), ...
        'Compact element labels should use element_id only.');
    numChecks = numChecks + 1;

    labelCounts = zeros(1, 3);
    for k = 1:3
        call_callback_local(runButton.ButtonPushedFcn, runButton);
        drawnow limitrate
        labelCounts(k) = numel(element_label_strings_local(rayAxes));
    end
    assert(max(labelCounts) == min(labelCounts) && labelCounts(1) > 0, ...
        'Repeated Run Trace should not duplicate element labels.');
    numChecks = numChecks + 1;

    labelStyle.Value = 'Detailed';
    call_callback_local(labelStyle.ValueChangedFcn, labelStyle);
    drawnow limitrate
    detailedLabels = element_label_strings_local(rayAxes);
    assert(any(contains(detailedLabels, "thin lens")) && ...
        ~any(contains(detailedLabels, "(")) && ...
        ~any(contains(detailedLabels, ")")), ...
        'Detailed element labels should include type text without parentheses.');
    numChecks = numChecks + 1;

    labelStyle.Value = 'Off';
    call_callback_local(labelStyle.ValueChangedFcn, labelStyle);
    drawnow limitrate
    assert(isempty(element_label_strings_local(rayAxes)), ...
        'Off label style should suppress element labels.');
    showLabels.Value = false;
    labelStyle.Value = 'Compact';
    call_callback_local(showLabels.ValueChangedFcn, showLabels);
    drawnow limitrate
    assert(isempty(element_label_strings_local(rayAxes)), ...
        'Show element labels checkbox should suppress labels when off.');
    numChecks = numChecks + 2;

    showLabels.Value = true;
    call_callback_local(showLabels.ValueChangedFcn, showLabels);
    objectType.Value = 'Grating object';
    call_callback_local(objectType.ValueChangedFcn, objectType);
    fieldMode.Value = 'Y field sweep';
    call_callback_local(fieldMode.ValueChangedFcn, fieldMode);
    fieldMin.Value = -1;
    fieldMax.Value = 1;
    fieldCount.Value = 3;
    call_callback_local(fieldMin.ValueChangedFcn, fieldMin);
    call_callback_local(fieldMax.ValueChangedFcn, fieldMax);
    call_callback_local(fieldCount.ValueChangedFcn, fieldCount);
    ordersField.Value = '-1:1';
    call_callback_local(ordersField.ValueChangedFcn, ordersField);
    call_callback_local(runButton.ButtonPushedFcn, runButton);
    drawnow limitrate
    gratingSeconds = parse_run_time_local(timingLabel.Text);
    pairs = grating_launch_pairs_local(rayAxes, objectZ.Value);
    assert(isfinite(gratingSeconds) && gratingSeconds >= 0 && ...
        height(pairs) >= 9 && ...
        all(arrayfun(@(v) any_close_local(pairs.y, v), [-1 0 1])) && ...
        all(ismember(["m = -1"; "m = 0"; "m = +1"], pairs.order)), ...
        'Grating mode should trace y-field height by diffraction order.');
    numChecks = numChecks + 2;

    labels = grating_order_label_strings_local(rayAxes);
    assert(all(ismember(["m = -1"; "m = 0"; "m = +1"], labels)), ...
        'Grating order labels should show propagating orders.');
    numChecks = numChecks + 1;

    legendLabels = legend_labels_local(app.UIFigure);
    assert(numel(legendLabels) == numel(unique(legendLabels)) && ...
        all(ismember(["m = -1"; "m = 0"; "m = +1"], legendLabels)), ...
        'Grating legend entries should remain clean and by order.');
    numChecks = numChecks + 1;

    repeatedLegendCounts = zeros(1, 3);
    for k = 1:3
        call_callback_local(runButton.ButtonPushedFcn, runButton);
        drawnow limitrate
        legendLabels = legend_labels_local(app.UIFigure);
        assert(numel(legendLabels) == numel(unique(legendLabels)) && ...
            all(ismember(["m = -1"; "m = 0"; "m = +1"], legendLabels)), ...
            'Repeated grating Run Trace should keep legend entries unique.');
        repeatedLegendCounts(k) = numel(legendLabels);
    end
    assert(max(repeatedLegendCounts) == min(repeatedLegendCounts), ...
        'Repeated grating Run Trace should not duplicate legend entries.');
    numChecks = numChecks + 1;

    prescriptionTable.Data = table_to_prescription_yu(originalPrescription);

    status = "passed";
end


function [numChecks, originalPrescription] = prescription_io_checks_local( ...
        app, prescriptionTable)
    numChecks = 0;
    originalPrescription = nparaxial_validate_prescription_yu( ...
        prescriptionTable.Data);
    csvFile = [tempname, '.csv'];
    matFile = [tempname, '.mat'];
    cleanupCsv = onCleanup(@() delete_if_exists_local(csvFile)); %#ok<NASGU>
    cleanupMat = onCleanup(@() delete_if_exists_local(matFile)); %#ok<NASGU>

    savedCsv = app.savePrescriptionCsv(csvFile);
    csvInfo = dir(csvFile);
    assert(~isempty(csvInfo) && csvInfo.bytes > 0, ...
        'Save prescription CSV should create a non-empty file.');
    assert_prescriptions_equal_local(savedCsv, originalPrescription);
    numChecks = numChecks + 2;

    prescriptionTable.Data = nparaxial_default_prescription_yu( ...
        "Single thin lens");
    loadedCsv = app.loadPrescriptionCsv(csvFile);
    validatedCsv = nparaxial_validate_prescription_yu( ...
        prescriptionTable.Data);
    assert_prescriptions_equal_local(loadedCsv, originalPrescription);
    assert_prescriptions_equal_local(validatedCsv, originalPrescription);
    numChecks = numChecks + 2;

    savedMat = app.savePrescriptionMat(matFile);
    matInfo = dir(matFile);
    S = load(matFile);
    assert(~isempty(matInfo) && matInfo.bytes > 0 && ...
        isfield(S, 'prescription'), ...
        'Save prescription MAT should create variable prescription.');
    assert_prescriptions_equal_local(savedMat, originalPrescription);
    numChecks = numChecks + 2;

    prescriptionTable.Data = nparaxial_default_prescription_yu( ...
        "Homogeneous translation / free-space propagation");
    loadedMat = app.loadPrescriptionMat(matFile);
    validatedMat = nparaxial_validate_prescription_yu( ...
        prescriptionTable.Data);
    assert_prescriptions_equal_local(loadedMat, originalPrescription);
    assert_prescriptions_equal_local(validatedMat, originalPrescription);
    numChecks = numChecks + 2;
end


function obj = find_by_tag_local(fig, className, tagValue)
    matches = findall(fig, '-isa', className, 'Tag', tagValue);
    if isempty(matches)
        error('Could not find %s tagged "%s".', className, tagValue);
    end
    obj = matches(1);
end


function assert_layout_dimensions_local(mainGrid, controlGrid, rayGrid, ...
        rayTopGrid, prescriptionButtonGrid)
    assert(numeric_cell_value_local(mainGrid.ColumnWidth, 1) >= 350, ...
        'V2 left control column should be widened.');
    assert(numeric_cell_value_local(controlGrid.ColumnWidth, 2) >= 155, ...
        'V2 trace control value column should be wide enough.');
    assert(numeric_cell_value_local(rayGrid.RowHeight, 1) >= 400, ...
        'Ray Diagram top controls should be tall enough.');
    assert(numeric_cell_value_local(rayTopGrid.ColumnWidth, 1) >= 450, ...
        'Ray fan/prescription controls should be wide enough.');
    assert(numeric_cell_value_local( ...
        prescriptionButtonGrid.ColumnWidth, 1) >= 160, ...
        'Prescription control label/button column should be wide enough.');
    assert(numel(prescriptionButtonGrid.RowHeight) == 12, ...
        'Prescription controls should reserve only editing-control rows.');
end


function value = numeric_cell_value_local(values, idx)
    value = NaN;
    if numel(values) >= idx && isnumeric(values{idx})
        value = double(values{idx});
    end
end


function assert_no_duplicate_action_buttons_local(panel)
    buttonTexts = strings_from_controls_local(findall(panel, ...
        '-isa', 'matlab.ui.control.Button'));
    duplicateActions = ["Run Trace"; "Load CSV"; "Save CSV"; ...
        "Load MAT"; "Save MAT"];
    for k = 1:numel(duplicateActions)
        assert(~any(buttonTexts == duplicateActions(k)), ...
            'Ray Fan / Prescription Controls should not include %s.', ...
            duplicateActions(k));
    end
end


function assert_prescription_edit_buttons_local(panel)
    buttonTexts = strings_from_controls_local(findall(panel, ...
        '-isa', 'matlab.ui.control.Button'));
    expectedButtons = [
        "Add Thin Lens"
        "Add Surface"
        "Add Stop"
        "Add Dummy"
        "Duplicate Row"
        "Delete Selected Row"
        "Sort Prescription"
        "Check Prescription"
        ];
    for k = 1:numel(expectedButtons)
        assert(any(buttonTexts == expectedButtons(k)), ...
            'Prescription editing button %s should remain.', ...
            expectedButtons(k));
    end
end


function assert_file_menu_prescription_actions_local(fig)
    menuTexts = strings_from_controls_local(findall(fig, 'Type', 'uimenu'));
    expectedMenus = [
        "Load prescription CSV"
        "Save prescription CSV"
        "Load prescription MAT"
        "Save prescription MAT"
        ];
    for k = 1:numel(expectedMenus)
        assert(any(menuTexts == expectedMenus(k)), ...
            'File menu item %s should remain.', expectedMenus(k));
    end
end


function values = strings_from_controls_local(handles)
    values = strings(numel(handles), 1);
    for k = 1:numel(handles)
        if isprop(handles(k), 'Text')
            values(k) = string(handles(k).Text);
        end
    end
    values = values(values ~= "");
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
    actual = nparaxial_validate_prescription_yu(actual);
    expected = nparaxial_validate_prescription_yu(expected);
    actual = table_to_prescription_yu(actual);
    expected = table_to_prescription_yu(expected);
    assert(isequal(string(actual.Properties.VariableNames), ...
        string(expected.Properties.VariableNames)), ...
        'Prescription tables should use the same schema.');
    assert(height(actual) == height(expected), ...
        'Prescription tables should have the same number of rows.');

    names = string(actual.Properties.VariableNames);
    for k = 1:numel(names)
        name = char(names(k));
        a = actual.(name);
        e = expected.(name);
        if isnumeric(a) || islogical(a)
            aDouble = double(a(:));
            eDouble = double(e(:));
            sameFinite = isfinite(aDouble) & isfinite(eDouble) & ...
                abs(aDouble - eDouble) < 1e-12;
            sameNaN = isnan(aDouble) & isnan(eDouble);
            sameInf = isinf(aDouble) & isinf(eDouble) & ...
                sign(aDouble) == sign(eDouble);
            assert(isequal(size(a), size(e)) && ...
                all(sameFinite | sameNaN | sameInf), ...
                'Numeric prescription column %s should roundtrip.', name);
        else
            assert(isequal(string(a), string(e)), ...
                'Text prescription column %s should roundtrip.', name);
        end
    end
end


function assert_no_x_field_controls_local(fig)
    h = findall(fig);
    tags = strings(numel(h), 1);
    for k = 1:numel(h)
        if isprop(h(k), 'Tag')
            tags(k) = string(h(k).Tag);
        end
    end
    tags = lower(tags(tags ~= ""));
    hasXField = any(contains(tags, "field_x")) || ...
        any(contains(tags, "x_field")) || ...
        any(contains(tags, "field_min_x")) || ...
        any(contains(tags, "field_max_x"));
    assert(~hasXField, 'V2 should not expose active x-field controls.');
end


function delete_if_exists_local(filename)
    if exist(filename, 'file') == 2
        delete(filename);
    end
end


function ys = launch_y_values_local(ax, zObj, displayNames)
    lines = findall(ax, 'Type', 'Line');
    ys = zeros(0, 1);
    for k = 1:numel(lines)
        if ~isprop(lines(k), 'DisplayName') || ...
                ~ismember(string(lines(k).DisplayName), displayNames)
            continue
        end
        x = double(lines(k).XData);
        y = double(lines(k).YData);
        if isempty(x) || isempty(y) || ~isfinite(x(1)) || ...
                abs(x(1) - zObj) > 1e-9
            continue
        end
        ys(end+1, 1) = y(1); %#ok<AGROW>
    end
end


function pairs = grating_launch_pairs_local(ax, zObj)
    lines = findall(ax, 'Type', 'Line');
    order = strings(0, 1);
    y = zeros(0, 1);
    for k = 1:numel(lines)
        if ~isprop(lines(k), 'DisplayName')
            continue
        end
        name = string(lines(k).DisplayName);
        if ~startsWith(name, "m = ")
            continue
        end
        xData = double(lines(k).XData);
        yData = double(lines(k).YData);
        if isempty(xData) || isempty(yData) || ...
                abs(xData(1) - zObj) > 1e-9
            continue
        end
        order(end+1, 1) = name; %#ok<AGROW>
        y(end+1, 1) = yData(1); %#ok<AGROW>
    end
    pairs = unique(table(order, y));
end


function labels = element_label_strings_local(ax)
    hText = findall(ax, ...
        'Tag', 'nparaxial_v2_element_label', ...
        'Type', 'Text');
    labels = text_strings_local(hText);
end


function labels = grating_order_label_strings_local(ax)
    hText = findall(ax, ...
        'Tag', 'nparaxial_v2_grating_order_label', ...
        'Type', 'Text');
    labels = text_strings_local(hText);
end


function labels = text_strings_local(hText)
    labels = strings(numel(hText), 1);
    for k = 1:numel(hText)
        labels(k) = string(hText(k).String);
    end
    labels = labels(:);
end


function labels = legend_labels_local(fig)
    legends = findall(fig, 'Type', 'Legend');
    labels = strings(0, 1);
    if isempty(legends)
        return
    end
    labels = string(legends(1).String);
    labels = labels(:);
    labels = labels(labels ~= "");
end


function tf = any_close_local(values, target)
    values = double(values(:));
    tf = any(abs(values - double(target)) < 1e-9);
end


function assert_color_local(actual, expected, message)
    actual = double(actual(:)).';
    expected = double(expected(:)).';
    assert(isequal(size(actual), size(expected)), ...
        'Color arrays have different sizes.');
    assert(max(abs(actual - expected)) < 1e-12, message);
end


function assert_color_not_equal_local(actual, expected, message)
    actual = double(actual(:)).';
    expected = double(expected(:)).';
    assert(max(abs(actual - expected)) > 1e-6, message);
end
