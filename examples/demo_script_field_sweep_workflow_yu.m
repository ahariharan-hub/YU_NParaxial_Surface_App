function out = demo_script_field_sweep_workflow_yu()
%DEMO_SCRIPT_FIELD_SWEEP_WORKFLOW_YU Quiet command-line sweep example.

    rootFolder = fileparts(fileparts(mfilename('fullpath')));
    addpath(fullfile(rootFolder, 'core'));
    addpath(fullfile(rootFolder, 'workflows'));

    prescription = nparaxial_default_prescription_yu("Single thin lens");
    raySettings = nparaxial_default_ray_settings_yu();
    sweepSettings = nparaxial_default_sweep_settings_yu();
    sweepSettings.field_min = -5;
    sweepSettings.field_max = 5;
    sweepSettings.n_field_points = 5;

    out = nparaxial_run_field_sweep_workflow_yu( ...
        prescription, sweepSettings, raySettings);
    fprintf('Field sweep workflow: points=%d, metric=%s\n', ...
        height(out.sweep_table), string(out.sweepSettings.metric_name));
end
