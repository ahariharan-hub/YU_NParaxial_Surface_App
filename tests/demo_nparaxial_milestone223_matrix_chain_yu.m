function results = demo_nparaxial_milestone223_matrix_chain_yu()
%DEMO_NPARAXIAL_MILESTONE223_MATRIX_CHAIN_YU Matrix-chain and UI smoke tests.

    testFolder = fileparts(mfilename('fullpath'));
    rootFolder = fileparts(testFolder);
    addpath(rootFolder);
    addpath(fullfile(rootFolder, 'core'));

    numChecks = 0;

    p = nparaxial_default_prescription_yu("single thin lens");
    img = nparaxial_solve_image_plane_yu(p, -120);
    chain = nparaxial_matrix_chain_yu(p, -120, img.z_img);
    assert_sequence_local(chain.steps.operation_type, ...
        ["translation"; "thinlens"; "translation"], ...
        'Single thin lens matrix chain order is wrong.');
    assert_matrix_match_local(chain.final_matrix, ...
        nparaxial_system_matrix_yu(p, -120, img.z_img));
    assert(contains(join(chain.factor_labels, " "), "L_L1"), ...
        'Single thin lens symbolic chain should contain L_L1.');
    numChecks = numChecks + 1;

    p = make_prescription_local( ...
        ["L1"; "L2"], [1; 2], ["thinlens"; "thinlens"], ...
        [0; 60], [Inf; Inf], [100; 150], [Inf; Inf], ...
        [1; 1], [1; 1]);
    chain = nparaxial_matrix_chain_yu(p, -40, 180);
    assert_sequence_local(chain.steps.operation_type, ...
        ["translation"; "thinlens"; "translation"; "thinlens"; "translation"], ...
        'Two-thin-lens matrix chain order is wrong.');
    elementRows = chain.steps.operation_type ~= "translation";
    assert_sequence_local(chain.steps.element_id(elementRows), ["L1"; "L2"], ...
        'Two-thin-lens element order is wrong.');
    assert_matrix_match_local(chain.final_matrix, ...
        nparaxial_system_matrix_yu(p, -40, 180));
    numChecks = numChecks + 1;

    p = nparaxial_default_prescription_yu("two-surface thick lens");
    chain = nparaxial_matrix_chain_yu(p, -50, 120);
    elementTypes = chain.steps.operation_type( ...
        chain.steps.operation_type ~= "translation");
    assert_sequence_local(elementTypes, ["surface"; "dummy"; "surface"], ...
        'Thick-lens chain should preserve surface/dummy/surface event order.');
    labels = join(chain.steps.matrix_label, " ");
    assert(contains(labels, "S_S1") && contains(labels, "S_S2"), ...
        'Thick-lens chain should label refracting surface matrices.');
    assert_matrix_match_local(chain.final_matrix, ...
        nparaxial_system_matrix_yu(p, -50, 120));
    numChecks = numChecks + 1;

    p = make_prescription_local( ...
        ["L_slow"; "L_fast"], [2; 1], ["thinlens"; "thinlens"], ...
        [0; 0], [Inf; Inf], [100; 200], [Inf; Inf], ...
        [1; 1], [1; 1]);
    chain = nparaxial_matrix_chain_yu(p, -10, 40);
    elementRows = chain.steps.operation_type ~= "translation";
    assert_sequence_local(chain.steps.element_id(elementRows), ...
        ["L_fast"; "L_slow"], ...
        'Same-z matrix chain should respect event_order before row order.');
    assert(any(contains(chain.steps.matrix_label, "same-plane separator")), ...
        'Same-z matrix chain should label T(0) same-plane separator rows.');
    assert_matrix_match_local(chain.final_matrix, ...
        nparaxial_system_matrix_yu(p, -10, 40));
    numChecks = numChecks + 1;

    appSmoke = app_smoke_local(rootFolder);
    if appSmoke == "passed"
        numChecks = numChecks + 1;
    end

    results = struct();
    results.case_name = "milestone223_matrix_chain";
    results.num_checks = numChecks;
    results.app_smoke = appSmoke;
end


function T = make_prescription_local( ...
    elementId, eventOrder, typeName, z, aperture, focalLength, radiusR, ...
    nBefore, nAfter)

    T = table;
    T.element_id = string(elementId(:));
    T.event_order = double(eventOrder(:));
    T.type = string(typeName(:));
    T.z = double(z(:));
    T.aperture_radius = double(aperture(:));
    T.focal_length = double(focalLength(:));
    T.radius_R = double(radiusR(:));
    T.n_before = double(nBefore(:));
    T.n_after = double(nAfter(:));
    T.enabled = true(height(T), 1);
    T = nparaxial_validate_prescription_yu(T);
end


function assert_sequence_local(actual, expected, message)
    actual = string(actual(:));
    expected = string(expected(:));
    assert(isequal(actual, expected), message);
end


function assert_matrix_match_local(actual, expected)
    diffNorm = max(abs(actual(:) - expected(:)));
    assert(diffNorm < 1e-10, ...
        'Matrix-chain final cumulative matrix does not match system matrix.');
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

    assert_menu_local(app.UIFigure, "File");
    assert_menu_local(app.UIFigure, "View");
    assert_menu_local(app.UIFigure, "Export Combined First-Order Report TXT");
    assert_menu_local(app.UIFigure, "Show System Matrix");
    assert_menu_local(app.UIFigure, "Refresh Current View");
    oldRefreshMenu = findall(app.UIFigure, 'Text', 'Reset View / Refresh Layout');
    assert(isempty(oldRefreshMenu), ...
        'View menu should not advertise a layout reset that only refreshes data.');

    rayAxes = findall(app.UIFigure, '-isa', 'matlab.ui.control.UIAxes');
    assert(~isempty(rayAxes), ...
        'App smoke test could not find ray diagram axes.');

    tables = findall(app.UIFigure, '-isa', 'matlab.ui.control.Table');
    prescriptionTableMask = arrayfun(@is_prescription_table_local, tables);
    assert(sum(prescriptionTableMask) == 1, ...
        'App should expose exactly one authoritative prescription table.');
    prescriptionTable = tables(prescriptionTableMask);
    editable = prescriptionTable(1).ColumnEditable;
    assert(numel(editable) == 10 && all(logical(editable(:))), ...
        'The single prescription table should be editable.');

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

    runButton = findall(app.UIFigure, ...
        '-isa', 'matlab.ui.control.Button', 'Text', 'Run Trace');
    assert(~isempty(runButton), ...
        'App smoke test could not find Run Trace button.');
    call_callback_local(runButton(1).ButtonPushedFcn, runButton(1));
    drawnow limitrate

    systemMenu = assert_menu_local(app.UIFigure, "Show System Matrix");
    call_callback_local(systemMenu(1).MenuSelectedFcn, systemMenu(1));
    drawnow limitrate

    tables = findall(app.UIFigure, '-isa', 'matlab.ui.control.Table');
    assert(any(arrayfun(@is_matrix_chain_table_local, tables)), ...
        'System Matrix tab should contain a matrix-chain step table.');

    textAreas = findall(app.UIFigure, '-isa', 'matlab.ui.control.TextArea');
    text = strings(0, 1);
    for k = 1:numel(textAreas)
        text(end+1, 1) = join(string(textAreas(k).Value), newline); %#ok<AGROW>
    end
    joinedText = join(text, newline);
    assert(contains(joinedText, "Matrix-chain convention"), ...
        'System Matrix tab should show matrix-chain text.');
    assert(contains(joinedText, "Final cumulative M"), ...
        'System Matrix tab should show the final cumulative matrix block.');
    assert(contains(joinedText, "same-plane separator"), ...
        'System Matrix tab should explain T(0) same-plane separator rows.');

    numericFields = findall(app.UIFigure, ...
        '-isa', 'matlab.ui.control.NumericEditField');
    assert(~isempty(numericFields), ...
        'App smoke test could not find numeric edit fields.');
    numericFields(1).Value = numericFields(1).Value + 1;
    call_callback_local(numericFields(1).ValueChangedFcn, numericFields(1));
    drawnow limitrate
    assert_status_contains_local(app, ...
        "Inputs changed. Run Trace to refresh diagnostics.");

    exportMenus = [
        "Export Cardinal Data CSV"
        "Export Vignetting CSV"
        "Export Combined First-Order Report TXT"
        ];
    for k = 1:numel(exportMenus)
        exportMenu = assert_menu_local(app.UIFigure, exportMenus(k));
        call_callback_local(exportMenu(1).MenuSelectedFcn, exportMenu(1));
        drawnow limitrate
        assert_status_contains_local(app, ...
            "Inputs changed. Run Trace to refresh diagnostics.");
    end

    status = "passed";
end


function menu = assert_menu_local(fig, textValue)
    menu = findall(fig, 'Text', char(textValue));
    menu = menu(arrayfun(@(h) isa(h, 'matlab.ui.container.Menu'), menu));
    assert(~isempty(menu), ...
        'App smoke test could not find expected menu item.');
end


function tf = is_prescription_table_local(uiTable)
    data = uiTable.Data;
    tf = istable(data) && all(ismember( ...
        ["element_id", "event_order", "type", "z", "enabled"], ...
        string(data.Properties.VariableNames)));
end


function tf = is_matrix_chain_table_local(uiTable)
    data = uiTable.Data;
    tf = istable(data) && all(ismember( ...
        ["step_index", "operation_type", "matrix_label", "cumulative_A"], ...
        string(data.Properties.VariableNames))) && height(data) > 0;
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
