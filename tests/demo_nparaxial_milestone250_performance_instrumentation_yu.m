function results = demo_nparaxial_milestone250_performance_instrumentation_yu()
%DEMO_NPARAXIAL_MILESTONE250_PERFORMANCE_INSTRUMENTATION_YU Timing checks.

    testFolder = fileparts(mfilename('fullpath'));
    rootFolder = fileparts(testFolder);
    addpath(rootFolder);
    addpath(fullfile(rootFolder, 'core'));

    numChecks = 0;

    timer = nparaxial_perf_timer_yu("new", true);
    timer = nparaxial_perf_timer_yu("start", timer, "alpha section");
    pause(0.001);
    timer = nparaxial_perf_timer_yu("stop", timer, "alpha section");
    timer = nparaxial_perf_timer_yu( ...
        "add_elapsed", timer, "beta section", 0.002);
    logTable = nparaxial_perf_timer_yu("table", timer);
    assert(istable(logTable) && height(logTable) >= 2, ...
        'Timing helper should record start/stop and explicit elapsed entries.');
    numChecks = numChecks + 1;

    summaryTable = nparaxial_perf_timer_yu("summary", timer);
    assert(all(ismember(["alpha section"; "beta section"], ...
        summaryTable.section)), ...
        'Timing summary should contain expected section names.');
    numChecks = numChecks + 1;

    assert(all(isfinite(logTable.elapsed_s)) && ...
        all(logTable.elapsed_s >= 0), ...
        'Elapsed timings should be finite and nonnegative.');
    numChecks = numChecks + 1;

    disabled = nparaxial_perf_timer_yu("new", false);
    disabled = nparaxial_perf_timer_yu("start", disabled, "disabled");
    disabled = nparaxial_perf_timer_yu("stop", disabled, "disabled");
    disabled = nparaxial_perf_timer_yu( ...
        "add_elapsed", disabled, "disabled", 1);
    assert(isempty(nparaxial_perf_timer_yu("table", disabled)), ...
        'Disabled timing mode should not record entries or error.');
    numChecks = numChecks + 1;

    exportTimer = nparaxial_perf_timer_yu("new", true);
    exportFile = [tempname, '.txt'];
    cleanupFile = onCleanup(@() delete_if_exists_local(exportFile)); %#ok<NASGU>
    tPerf = tic;
    nparaxial_export_summary_txt_yu( ...
        ["Performance instrumentation export smoke"; "ok"], exportFile);
    exportTimer = nparaxial_perf_timer_yu( ...
        "add_elapsed", exportTimer, "export/report generation", toc(tPerf));
    exportSummary = nparaxial_perf_timer_yu("summary", exportTimer);
    assert(any(exportSummary.section == "export/report generation"), ...
        'Export/report generation timing should be recordable.');
    numChecks = numChecks + 1;

    [appSmoke, appTiming] = app_smoke_local(rootFolder);
    if appSmoke == "passed"
        requiredSections = [
            "image solve/classification"
            "ray fan generation"
            "ray tracing"
            "cardinal diagnostics"
            "pupil/stop diagnostics"
            "vignetting interval calculation"
            "paraxial-validity diagnostics"
            "Ray Diagram redraw"
            "legend update"
            "plot overlays"
            "field-sweep calculation"
            "Basic Run Trace"
            "Explicit Paraxial Validity update"
        ];
        assert(all(ismember(requiredSections, appTiming.section)), ...
            'App timing table should contain the required instrumentation sections.');
        assert(all(isfinite(appTiming.total_elapsed_s)) && ...
            all(appTiming.total_elapsed_s >= 0), ...
            'App timing summary should contain finite nonnegative totals.');
        numChecks = numChecks + 1;
    end

    results = struct();
    results.case_name = "milestone250_performance_instrumentation";
    results.num_checks = numChecks;
    results.app_smoke = appSmoke;
    results.top_slow_sections = top_sections_local(appTiming, 5);
end


function [status, timingTable] = app_smoke_local(rootFolder)
    status = "skipped";
    timingTable = table();
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

    presetDropdown = find_dropdown_with_item_local( ...
        app.UIFigure, "Single thin lens");
    presetDropdown.Value = 'Single thin lens';
    presetButton = find_button_local(app.UIFigure, 'Load Default');
    call_callback_local(presetButton.ButtonPushedFcn, presetButton);
    drawnow limitrate

    runButton = find_button_local(app.UIFigure, 'Run Trace');
    call_callback_local(runButton.ButtonPushedFcn, runButton);
    drawnow limitrate

    updateValidityButton = find_button_local( ...
        app.UIFigure, 'Update Validity Diagnostics');
    call_callback_local(updateValidityButton.ButtonPushedFcn, ...
        updateValidityButton);
    drawnow limitrate

    updateSweepButton = find_button_local(app.UIFigure, 'Update Validity Plot');
    call_callback_local(updateSweepButton.ButtonPushedFcn, updateSweepButton);
    drawnow limitrate

    performanceTab = find_tab_local(app.UIFigure, 'Performance');
    performanceTab.Parent.SelectedTab = performanceTab;
    if ~isempty(performanceTab.Parent.SelectionChangedFcn)
        call_callback_local( ...
            performanceTab.Parent.SelectionChangedFcn, performanceTab.Parent);
    end
    drawnow limitrate

    perfTable = findall(app.UIFigure, ...
        '-isa', 'matlab.ui.control.Table', ...
        'Tag', 'nparaxial_performance_table');
    assert(~isempty(perfTable), ...
        'App smoke should find the performance timing table.');
    timingTable = perfTable(1).Data;
    assert(istable(timingTable) && ~isempty(timingTable), ...
        'Performance table should be populated after trace and field sweep.');

    status = "passed";
end


function sections = top_sections_local(T, n)
    if ~istable(T) || isempty(T)
        sections = strings(0, 1);
        return
    end
    n = min(n, height(T));
    sections = T.section(1:n);
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


function button = find_button_local(fig, textValue)
    buttons = findall(fig, '-isa', 'matlab.ui.control.Button', ...
        'Text', char(textValue));
    if isempty(buttons)
        error('Could not find button "%s".', textValue);
    end
    button = buttons(1);
end


function tab = find_tab_local(fig, titleText)
    tabs = findall(fig, '-isa', 'matlab.ui.container.Tab', ...
        'Title', char(titleText));
    if isempty(tabs)
        error('Could not find tab "%s".', titleText);
    end
    tab = tabs(1);
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


function delete_if_exists_local(filename)
    if exist(filename, 'file') == 2
        delete(filename);
    end
end
