function opts = nparaxial_default_workflow_opts_yu()
%NPARAXIAL_DEFAULT_WORKFLOW_OPTS_YU Defaults for scriptable workflows.

    opts = struct();
    opts.tol = 1e-12;
    opts.computeValidity = false;
    opts.computeCardinal = true;
    opts.computePupilStop = false;
    opts.timingEnabled = true;
    opts.z_final = [];
end
