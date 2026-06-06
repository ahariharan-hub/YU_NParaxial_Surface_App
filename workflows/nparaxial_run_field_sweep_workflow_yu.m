function out = nparaxial_run_field_sweep_workflow_yu( ...
    prescription, sweepSettings, raySettings, opts)
%NPARAXIAL_RUN_FIELD_SWEEP_WORKFLOW_YU Scriptable paraxial-validity sweep.

    ensure_workflow_paths_local();
    if nargin < 1 || isempty(prescription)
        prescription = nparaxial_default_prescription_yu();
    end
    if nargin < 2
        sweepSettings = struct();
    end
    if nargin < 3
        raySettings = struct();
    end
    if nargin < 4
        opts = struct();
    end

    sweepSettings = normalize_sweep_settings_local( ...
        sweepSettings, raySettings);
    raySettings = normalize_ray_settings_local(raySettings);
    opts = normalize_opts_local(opts);
    timer = nparaxial_perf_timer_yu("new", opts.timingEnabled);

    tPerf = tic;
    prescription = nparaxial_validate_prescription_yu(prescription);
    timer = nparaxial_perf_timer_yu( ...
        "add_elapsed", timer, "prescription validation", toc(tPerf));

    validitySettings = struct();
    if isfinite(opts.z_final)
        validitySettings.z_final = opts.z_final;
    elseif isfinite(raySettings.z_final)
        validitySettings.z_final = raySettings.z_final;
    end

    fieldHeights = sweepSettings.field_heights(:);
    tPerf = tic;
    sweep = nparaxial_validity_field_sweep_yu( ...
        prescription, raySettings.z_obj, fieldHeights, raySettings, ...
        validitySettings, opts.tol);
    timer = nparaxial_perf_timer_yu( ...
        "add_elapsed", timer, "field-sweep calculation", toc(tPerf));

    tPerf = tic;
    [metricValues, metricStatus] = nparaxial_validity_field_sweep_metric_yu( ...
        sweep.sweep_summary_table, sweepSettings.metric_name);
    metricName = repmat(string(sweepSettings.metric_name), ...
        numel(metricValues), 1);
    metricStatusColumn = repmat(string(metricStatus), numel(metricValues), 1);
    metricTable = table( ...
        sweep.sweep_summary_table.y_field, metricName, metricValues, ...
        metricStatusColumn, ...
        'VariableNames', {'y_field', 'metric_name', 'metric_value', ...
        'status_text'});
    timer = nparaxial_perf_timer_yu( ...
        "add_elapsed", timer, "field-sweep metric extraction", toc(tPerf));

    out = struct();
    out.sweepSettings = sweepSettings;
    out.raySettings = raySettings;
    out.sweep = sweep;
    out.sweep_table = sweep.sweep_summary_table;
    out.metric_table = metricTable;
    out.metric_status = metricStatus;
    out.performance_timer = timer;
    out.performance_log = nparaxial_perf_timer_yu("table", timer);
    out.timing = nparaxial_perf_timer_yu("summary", timer);
    out.status = sweep.status_text;
end


function ensure_workflow_paths_local()
    workflowFolder = string(fileparts(mfilename('fullpath')));
    rootFolder = fileparts(workflowFolder);
    addpath(workflowFolder);
    coreFolder = fullfile(rootFolder, "core");
    if exist(coreFolder, 'dir')
        addpath(coreFolder);
    end
end


function settings = normalize_sweep_settings_local(sweepSettings, raySettings)
    defaults = nparaxial_default_sweep_settings_yu();
    settings = defaults;
    settings.field_min = double(get_first_field_local( ...
        sweepSettings, ["field_min", "y_min"], defaults.field_min));
    settings.field_max = double(get_first_field_local( ...
        sweepSettings, ["field_max", "y_max"], defaults.field_max));
    settings.n_field_points = round(double(get_first_field_local( ...
        sweepSettings, ["n_field_points", "field_count", "Nfield"], ...
        defaults.n_field_points)));
    settings.metric_name = string(get_first_field_local( ...
        sweepSettings, ["metric_name", "metric"], defaults.metric_name));
    settings.sweep_mode = string(get_first_field_local( ...
        sweepSettings, ["sweep_mode", "mode"], defaults.sweep_mode));

    fieldHeights = get_first_field_local( ...
        sweepSettings, ["field_heights", "fieldHeights"], []);
    if isempty(fieldHeights)
        switch lower(strtrim(string(settings.sweep_mode)))
            case "current field only"
                fieldHeights = double(get_first_field_local( ...
                    sweepSettings, ["field_height", "y_field"], ...
                    get_first_field_local(raySettings, ...
                    ["field_height", "y_field"], 0)));
            case "symmetric field sweep"
                extent = max(abs([settings.field_min, settings.field_max, ...
                    double(get_first_field_local(raySettings, ...
                    ["field_height", "y_field"], 0))]));
                if ~isfinite(extent) || extent <= 0
                    extent = max(abs([defaults.field_min, defaults.field_max]));
                end
                fieldHeights = linspace( ...
                    -extent, extent, max(1, settings.n_field_points)).';
                settings.field_min = -extent;
                settings.field_max = extent;
            otherwise
                fieldHeights = linspace(settings.field_min, ...
                    settings.field_max, max(1, settings.n_field_points)).';
        end
    end

    settings.field_heights = double(fieldHeights(:));
    settings.n_field_points = numel(settings.field_heights);
    if isempty(settings.field_heights) || any(~isfinite(settings.field_heights))
        error('sweepSettings field heights must be finite.');
    end
end


function settings = normalize_ray_settings_local(raySettings)
    defaults = nparaxial_default_ray_settings_yu();
    settings = struct();
    settings.z_obj = double(get_first_field_local( ...
        raySettings, ["z_obj", "zObj", "object_z"], defaults.z_obj));
    settings.mode = string(get_first_field_local( ...
        raySettings, ["mode", "fan_mode", "ray_fan_mode"], ...
        defaults.fan_mode));
    settings.n_rays = round(double(get_first_field_local( ...
        raySettings, ["n_rays", "Nrays", "nRays"], defaults.n_rays)));
    settings.manual_u_max = double(get_first_field_local( ...
        raySettings, ["manual_u_max", "u_max", "manualUMax"], ...
        defaults.manual_u_max));
    settings.z_final = double(get_first_field_local( ...
        raySettings, ["z_final", "zFinal"], NaN));

    if settings.n_rays < 3
        error('raySettings.n_rays must be at least 3.');
    end
    if mod(settings.n_rays, 2) == 0
        settings.n_rays = settings.n_rays + 1;
    end
    if ~isscalar(settings.z_obj) || ~isfinite(settings.z_obj)
        error('raySettings.z_obj must be finite.');
    end
    if ~isscalar(settings.manual_u_max) || ...
            ~isfinite(settings.manual_u_max) || settings.manual_u_max <= 0
        error('raySettings.manual_u_max must be positive finite.');
    end
end


function opts = normalize_opts_local(optsIn)
    defaults = nparaxial_default_workflow_opts_yu();
    opts = defaults;
    opts.tol = double(get_first_field_local(optsIn, "tol", defaults.tol));
    opts.timingEnabled = logical(get_first_field_local( ...
        optsIn, ["timingEnabled", "timing_enabled"], ...
        defaults.timingEnabled));
    opts.z_final = double(get_first_field_local( ...
        optsIn, ["z_final", "zFinal"], NaN));
    if ~isscalar(opts.tol) || ~isfinite(opts.tol) || opts.tol <= 0
        error('opts.tol must be positive finite.');
    end
end


function value = get_first_field_local(S, names, defaultValue)
    value = defaultValue;
    if ~isstruct(S)
        return
    end
    names = string(names);
    for k = 1:numel(names)
        name = char(names(k));
        if isfield(S, name) && ~isempty(S.(name))
            value = S.(name);
            return
        end
    end
end
