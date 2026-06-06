function sweepSettings = nparaxial_default_sweep_settings_yu()
%NPARAXIAL_DEFAULT_SWEEP_SETTINGS_YU Defaults for field-sweep workflows.

    sweepSettings = struct();
    sweepSettings.field_min = -5;
    sweepSettings.field_max = 5;
    sweepSettings.n_field_points = 5;
    sweepSettings.metric_name = "max_abs_translation_delta_y";
    sweepSettings.sweep_mode = "Custom min/max field sweep";
    sweepSettings.field_heights = [];
end
