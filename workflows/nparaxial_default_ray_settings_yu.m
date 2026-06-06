function raySettings = nparaxial_default_ray_settings_yu()
%NPARAXIAL_DEFAULT_RAY_SETTINGS_YU Defaults for scriptable trace workflows.

    raySettings = struct();
    raySettings.z_obj = -120;
    raySettings.field_height = 0;
    raySettings.field_heights = [];
    raySettings.n_rays = 9;
    raySettings.fan_mode = "Manual fixed-angle fan";
    raySettings.u_max = 0.04;
    raySettings.manual_u_max = 0.04;
    raySettings.z_final = [];
end
