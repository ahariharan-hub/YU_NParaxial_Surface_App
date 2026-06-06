function out = demo_script_trace_workflow_yu()
%DEMO_SCRIPT_TRACE_WORKFLOW_YU Quiet command-line trace workflow example.

    rootFolder = fileparts(fileparts(mfilename('fullpath')));
    addpath(fullfile(rootFolder, 'core'));
    addpath(fullfile(rootFolder, 'workflows'));

    prescription = nparaxial_default_prescription_yu("Single thin lens");
    raySettings = nparaxial_default_ray_settings_yu();
    raySettings.field_heights = [-5; 0; 5];

    out = nparaxial_run_trace_workflow_yu(prescription, raySettings);
    fprintf('Trace workflow: fields=%d, image=%s, validity=%d\n', ...
        numel(out.bundleSet), string(out.image.type), ~isempty(out.validity));
end
