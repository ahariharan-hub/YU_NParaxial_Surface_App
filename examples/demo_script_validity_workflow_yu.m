function out = demo_script_validity_workflow_yu()
%DEMO_SCRIPT_VALIDITY_WORKFLOW_YU Quiet command-line validity example.

    rootFolder = fileparts(fileparts(mfilename('fullpath')));
    addpath(fullfile(rootFolder, 'core'));
    addpath(fullfile(rootFolder, 'workflows'));

    prescription = nparaxial_default_prescription_yu("Single thin lens");
    raySettings = nparaxial_default_ray_settings_yu();
    raySettings.field_heights = [-5; 0; 5];

    out = nparaxial_run_validity_workflow_yu(prescription, raySettings);
    fprintf('Validity workflow: rays=%d, events=%d\n', ...
        height(out.validity.summary_table), ...
        height(out.validity.event_table));
end
