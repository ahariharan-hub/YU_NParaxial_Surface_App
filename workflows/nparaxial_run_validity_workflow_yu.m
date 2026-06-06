function out = nparaxial_run_validity_workflow_yu(prescription, raySettings, opts)
%NPARAXIAL_RUN_VALIDITY_WORKFLOW_YU Explicit scriptable validity diagnostic.

    ensure_workflow_paths_local();
    if nargin < 1 || isempty(prescription)
        prescription = nparaxial_default_prescription_yu();
    end
    if nargin < 2
        raySettings = struct();
    end
    if nargin < 3
        opts = struct();
    end

    opts = normalize_opts_local(opts);
    traceOpts = opts;
    traceOpts.computeValidity = false;

    trace = nparaxial_run_trace_workflow_yu( ...
        prescription, raySettings, traceOpts);
    timer = trace.performance_timer;

    tPerf = tic;
    validity = nparaxial_paraxial_validity_yu( ...
        trace.bundleSet, trace.prescription, [], opts.tol);
    timer = nparaxial_perf_timer_yu( ...
        "add_elapsed", timer, "paraxial-validity diagnostics", toc(tPerf));

    out = struct();
    out.trace = trace;
    out.validity = validity;
    out.performance_timer = timer;
    out.performance_log = nparaxial_perf_timer_yu("table", timer);
    out.timing = nparaxial_perf_timer_yu("summary", timer);
    out.status = "Validity workflow completed.";
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


function opts = normalize_opts_local(optsIn)
    defaults = nparaxial_default_workflow_opts_yu();
    opts = defaults;
    opts.tol = get_field_local(optsIn, 'tol', defaults.tol);
    opts.computeCardinal = get_field_local( ...
        optsIn, 'computeCardinal', defaults.computeCardinal);
    opts.computePupilStop = get_field_local( ...
        optsIn, 'computePupilStop', defaults.computePupilStop);
    opts.timingEnabled = get_field_local( ...
        optsIn, 'timingEnabled', defaults.timingEnabled);
    opts.z_final = get_field_local(optsIn, 'z_final', defaults.z_final);
    opts.computeValidity = true;
end


function value = get_field_local(S, name, defaultValue)
    value = defaultValue;
    if isstruct(S) && isfield(S, name) && ~isempty(S.(name))
        value = S.(name);
    end
end
