function out = nparaxial_run_trace_workflow_yu(prescription, raySettings, opts)
%NPARAXIAL_RUN_TRACE_WORKFLOW_YU Scriptable basic y-u paraxial trace.
%
% The default workflow intentionally skips full paraxial-validity
% diagnostics. Set opts.computeValidity = true, or call
% nparaxial_run_validity_workflow_yu, when that heavy diagnostic is needed.

    ensure_core_path_local();
    if nargin < 1 || isempty(prescription)
        prescription = nparaxial_default_prescription_yu();
    end
    if nargin < 2
        raySettings = struct();
    end
    if nargin < 3
        opts = struct();
    end

    settings = normalize_ray_settings_local(raySettings);
    opts = normalize_opts_local(opts);
    timer = nparaxial_perf_timer_yu("new", opts.timingEnabled);

    tPerf = tic;
    prescription = nparaxial_validate_prescription_yu(prescription);
    timer = nparaxial_perf_timer_yu( ...
        "add_elapsed", timer, "prescription validation", toc(tPerf));

    tPerf = tic;
    eventSequence = nparaxial_event_sequence_yu(prescription);
    timer = nparaxial_perf_timer_yu( ...
        "add_elapsed", timer, "event sequence creation", toc(tPerf));

    tPerf = tic;
    img = nparaxial_solve_image_plane_yu( ...
        prescription, settings.z_obj, opts.tol);
    timer = nparaxial_perf_timer_yu( ...
        "add_elapsed", timer, "image solve/classification", toc(tPerf));

    zTrace = img.trace_z_final;
    if isfinite(settings.z_final)
        zTrace = settings.z_final;
    elseif isfinite(opts.z_final)
        zTrace = opts.z_final;
    end
    if ~isscalar(zTrace) || ~isfinite(zTrace) || zTrace < settings.z_obj
        error('Trace workflow z_final must be finite and after z_obj.');
    end

    tPerf = tic;
    matrixChain = nparaxial_matrix_chain_yu( ...
        prescription, settings.z_obj, zTrace);
    timer = nparaxial_perf_timer_yu( ...
        "add_elapsed", timer, "system matrix calculation", toc(tPerf));

    fieldHeights = settings.field_heights(:);
    bundleSet = struct([]);
    rayFanInfo = struct([]);
    for k = 1:numel(fieldHeights)
        yField = fieldHeights(k);
        tPerf = tic;
        [rays, fanInfo] = make_rays_local( ...
            prescription, settings, yField, zTrace, opts.tol);
        timer = nparaxial_perf_timer_yu( ...
            "add_elapsed", timer, "ray fan generation", toc(tPerf));

        if height(rays) > 0
            rays.name = "field_" + string(k) + "_" + rays.name;
            rays.ray_name = rays.name;
        end

        tPerf = tic;
        if height(rays) > 0
            bundle = nparaxial_trace_bundle_yu(rays, prescription, zTrace);
        else
            bundle = empty_trace_bundle_local();
        end
        timer = nparaxial_perf_timer_yu( ...
            "add_elapsed", timer, "ray tracing", toc(tPerf));

        bundleSet(k).field_index = k; %#ok<AGROW>
        bundleSet(k).y_obj = yField; %#ok<AGROW>
        bundleSet(k).rays = rays; %#ok<AGROW>
        bundleSet(k).bundle = bundle; %#ok<AGROW>
        bundleSet(k).ray_fan_info = fanInfo; %#ok<AGROW>
        if k == 1
            rayFanInfo = repmat(fanInfo, numel(fieldHeights), 1);
        else
            rayFanInfo(k) = fanInfo;
        end
    end

    cardinal = [];
    cardinalError = "";
    if opts.computeCardinal
        tPerf = tic;
        try
            elements = nparaxial_enabled_elements_yu(prescription);
            cardinal = nparaxial_cardinal_points_yu( ...
                prescription, elements.z(1), elements.z(end), opts.tol);
        catch ME
            cardinalError = string(ME.message);
        end
        timer = nparaxial_perf_timer_yu( ...
            "add_elapsed", timer, "cardinal diagnostics", toc(tPerf));
    end

    stopPupil = [];
    stopPupilError = "";
    if opts.computePupilStop
        tPerf = tic;
        try
            stopPupil = compute_stop_pupil_local( ...
                prescription, settings.z_obj, opts.tol);
        catch ME
            stopPupilError = string(ME.message);
        end
        timer = nparaxial_perf_timer_yu( ...
            "add_elapsed", timer, "pupil/stop diagnostics", toc(tPerf));
    end

    validity = [];
    validityError = "";
    if opts.computeValidity
        tPerf = tic;
        try
            validity = nparaxial_paraxial_validity_yu( ...
                bundleSet, prescription, [], opts.tol);
        catch ME
            validityError = string(ME.message);
        end
        timer = nparaxial_perf_timer_yu( ...
            "add_elapsed", timer, "paraxial-validity diagnostics", ...
            toc(tPerf));
    end

    out = struct();
    out.prescription = prescription;
    out.raySettings = settings;
    out.opts = opts;
    out.rays = first_field_value_local(bundleSet, "rays", table());
    out.bundle = first_field_value_local( ...
        bundleSet, "bundle", empty_trace_bundle_local());
    out.bundleSet = bundleSet;
    out.rayFanInfo = rayFanInfo;
    out.eventSequence = eventSequence;
    out.systemMatrix = img.M_ref;
    out.traceMatrix = matrixChain.final_matrix;
    out.matrixChain = matrixChain;
    out.image = img;
    out.trace_z_final = zTrace;
    out.cardinal = cardinal;
    out.cardinal_error = cardinalError;
    out.stopPupil = stopPupil;
    out.stop_pupil_error = stopPupilError;
    out.validity = validity;
    out.validity_error = validityError;
    out.performance_timer = timer;
    out.performance_log = nparaxial_perf_timer_yu("table", timer);
    out.timing = nparaxial_perf_timer_yu("summary", timer);
    if opts.computeValidity
        out.status = "Trace workflow completed with paraxial-validity diagnostics.";
    else
        out.status = ...
            "Basic trace workflow completed; paraxial-validity diagnostics were not computed.";
    end
end


function ensure_core_path_local()
    workflowFolder = string(fileparts(mfilename('fullpath')));
    rootFolder = fileparts(workflowFolder);
    coreFolder = fullfile(rootFolder, "core");
    if exist(coreFolder, 'dir')
        addpath(coreFolder);
    end
end


function settings = normalize_ray_settings_local(raySettings)
    defaults = nparaxial_default_ray_settings_yu();
    settings = defaults;
    settings.z_obj = double(get_first_field_local( ...
        raySettings, ["z_obj", "zObj", "object_z"], defaults.z_obj));
    settings.n_rays = round(double(get_first_field_local( ...
        raySettings, ["n_rays", "Nrays", "nRays"], defaults.n_rays)));
    settings.fan_mode = string(get_first_field_local( ...
        raySettings, ["fan_mode", "mode", "ray_fan_mode"], ...
        defaults.fan_mode));
    settings.u_max = double(get_first_field_local( ...
        raySettings, ["u_max", "manual_u_max", "manualUMax"], ...
        defaults.u_max));
    settings.manual_u_max = settings.u_max;
    settings.z_final = double(get_first_field_local( ...
        raySettings, ["z_final", "zFinal"], NaN));

    fieldHeights = get_first_field_local( ...
        raySettings, ["field_heights", "fieldHeights"], []);
    if isempty(fieldHeights)
        if has_any_field_local(raySettings, ["field_min", "field_max"])
            fieldMin = double(get_first_field_local( ...
                raySettings, ["field_min", "y_min", "yMin"], 0));
            fieldMax = double(get_first_field_local( ...
                raySettings, ["field_max", "y_max", "yMax"], 0));
            nFields = round(double(get_first_field_local( ...
                raySettings, ["n_field_points", "field_count", "Nfield"], 1)));
            nFields = max(1, nFields);
            if nFields == 1
                fieldHeights = mean([fieldMin, fieldMax]);
            else
                fieldHeights = linspace(fieldMin, fieldMax, nFields).';
            end
        else
            fieldHeights = double(get_first_field_local( ...
                raySettings, ["field_height", "y_field", "y_obj"], ...
                defaults.field_height));
        end
    end
    settings.field_heights = double(fieldHeights(:));
    if isempty(settings.field_heights) || any(~isfinite(settings.field_heights))
        error('raySettings field height values must be finite.');
    end
    settings.field_height = settings.field_heights(1);

    if ~isscalar(settings.z_obj) || ~isfinite(settings.z_obj)
        error('raySettings.z_obj must be finite.');
    end
    if settings.n_rays < 3
        error('raySettings.n_rays must be at least 3.');
    end
    if mod(settings.n_rays, 2) == 0
        settings.n_rays = settings.n_rays + 1;
    end
    if ~isscalar(settings.u_max) || ~isfinite(settings.u_max) || ...
            settings.u_max <= 0
        error('raySettings.u_max must be positive finite.');
    end
end


function opts = normalize_opts_local(optsIn)
    defaults = nparaxial_default_workflow_opts_yu();
    opts = defaults;
    opts.tol = double(get_first_field_local( ...
        optsIn, "tol", defaults.tol));
    opts.computeValidity = logical(get_first_field_local( ...
        optsIn, ["computeValidity", "compute_validity"], ...
        defaults.computeValidity));
    opts.computeCardinal = logical(get_first_field_local( ...
        optsIn, ["computeCardinal", "compute_cardinal"], ...
        defaults.computeCardinal));
    opts.computePupilStop = logical(get_first_field_local( ...
        optsIn, ["computePupilStop", "compute_pupil_stop"], ...
        defaults.computePupilStop));
    opts.timingEnabled = logical(get_first_field_local( ...
        optsIn, ["timingEnabled", "timing_enabled"], ...
        defaults.timingEnabled));
    opts.z_final = double(get_first_field_local( ...
        optsIn, ["z_final", "zFinal"], NaN));
    if ~isscalar(opts.tol) || ~isfinite(opts.tol) || opts.tol <= 0
        error('opts.tol must be positive finite.');
    end
end


function [rays, fanInfo] = make_rays_local( ...
    prescription, settings, yField, zTrace, tol)

    if settings.fan_mode == "Aperture-limited admitted cone"
        rays = nparaxial_make_aperture_limited_rays_yu( ...
            prescription, settings.z_obj, yField, settings.n_rays, ...
            settings.u_max, tol, zTrace);
    else
        rays = nparaxial_make_manual_fan_rays_yu( ...
            settings.z_obj, yField, settings.n_rays, settings.u_max);
    end
    fanInfo = rays.Properties.UserData;
end


function stopPupil = compute_stop_pupil_local(prescription, zObj, tol)
    elements = nparaxial_enabled_elements_yu(prescription);
    stopPupil = struct();
    stopPupil.stop = nparaxial_select_aperture_stop_yu( ...
        prescription, zObj, 0, tol);
    stopPupil.pupil = [];
    if ~isempty(stopPupil.stop) && stopPupil.stop.has_stop
        stopPupil.pupil = nparaxial_pupil_diagnostics_yu( ...
            prescription, elements.z(1), elements.z(end), ...
            stopPupil.stop.selected_event_index, tol);
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


function tf = has_any_field_local(S, names)
    tf = false;
    if ~isstruct(S)
        return
    end
    names = string(names);
    for k = 1:numel(names)
        name = char(names(k));
        if isfield(S, name) && ~isempty(S.(name))
            tf = true;
            return
        end
    end
end


function value = first_field_value_local(S, fieldName, defaultValue)
    value = defaultValue;
    if ~isempty(S) && isfield(S, fieldName)
        value = S(1).(fieldName);
    end
end


function bundle = empty_trace_bundle_local()
    bundle = struct( ...
        'name', {}, ...
        'ray_in', {}, ...
        'res', {}, ...
        'trc', {}, ...
        'yf', {}, ...
        'uf', {});
end
