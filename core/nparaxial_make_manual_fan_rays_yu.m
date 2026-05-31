function rays = nparaxial_make_manual_fan_rays_yu( ...
    z_obj, y_obj, n_rays, manual_u_max, sampling_mode, status_text)
%NPARAXIAL_MAKE_MANUAL_FAN_RAYS_YU Build a fixed-angle paraxial ray fan.
%
% The app convention is paraxial y-u with u in radians. This helper does
% not apply any paraxial-validity or exact-angle correction.

    if nargin < 5 || strlength(string(sampling_mode)) == 0
        sampling_mode = "Manual fixed-angle fan";
    end
    if nargin < 6 || strlength(string(status_text)) == 0
        status_text = "Manual fixed-angle fan.";
    end

    validate_inputs_local(z_obj, y_obj, n_rays, manual_u_max);
    n_rays = normalize_ray_count_local(n_rays);

    u0 = linspace(-manual_u_max, manual_u_max, n_rays).';
    u_fraction = linspace(0, 1, n_rays).';
    names = manual_ray_names_local(n_rays);

    rays = ray_table_local( ...
        names, z_obj, y_obj, u0, string(sampling_mode), ...
        -manual_u_max, manual_u_max, 0, u_fraction, "", "", ...
        false, false, string(status_text));

    rays.Properties.UserData = info_local( ...
        string(sampling_mode), -manual_u_max, manual_u_max, 0, ...
        -manual_u_max, manual_u_max, "", "", false, false, ...
        string(status_text));
end


function validate_inputs_local(z_obj, y_obj, n_rays, manual_u_max)
    if ~isscalar(z_obj) || ~isfinite(z_obj) || ...
            ~isscalar(y_obj) || ~isfinite(y_obj)
        error('z_obj and y_obj must be finite scalar values.');
    end
    if ~isscalar(n_rays) || ~isfinite(n_rays)
        error('n_rays must be a finite scalar value.');
    end
    if ~isscalar(manual_u_max) || ~isfinite(manual_u_max) || manual_u_max <= 0
        error('manual_u_max must be a positive finite scalar value.');
    end
end


function n_rays = normalize_ray_count_local(n_rays)
    n_rays = round(n_rays);
    if n_rays < 3
        error('n_rays must be at least 3.');
    end
    if mod(n_rays, 2) == 0
        n_rays = n_rays + 1;
    end
end


function names = manual_ray_names_local(n_rays)
    names = "ray_" + string((1:n_rays).');
    mid = (n_rays + 1)/2;
    names(1) = "lower_marginal";
    names(mid) = "chief";
    names(end) = "upper_marginal";
end


function rays = ray_table_local( ...
    names, z_obj, y_obj, u0, sampling_mode, u_low, u_high, u_center, ...
    u_fraction, lower_id, upper_id, fallback_used, fully_vignetted, ...
    status_text)

    n = numel(u0);
    rays = table;
    rays.ray_name = string(names(:));
    rays.name = rays.ray_name;
    rays.z0 = repmat(double(z_obj), n, 1);
    rays.y0 = repmat(double(y_obj), n, 1);
    rays.u0 = double(u0(:));
    rays.sampling_mode = repmat(string(sampling_mode), n, 1);
    rays.u_low = repmat(double(u_low), n, 1);
    rays.u_high = repmat(double(u_high), n, 1);
    rays.u_center = repmat(double(u_center), n, 1);
    rays.u_fraction = double(u_fraction(:));
    rays.lower_limiter_element_id = repmat(string(lower_id), n, 1);
    rays.upper_limiter_element_id = repmat(string(upper_id), n, 1);
    rays.fallback_used = repmat(logical(fallback_used), n, 1);
    rays.fully_vignetted = repmat(logical(fully_vignetted), n, 1);
    rays.status_text = repmat(string(status_text), n, 1);
    rays.z_target = NaN(n, 1);
    rays.y_target = NaN(n, 1);
end


function info = info_local( ...
    sampling_mode, used_u_low, used_u_high, used_u_center, ...
    allowed_u_low, allowed_u_high, lower_id, upper_id, fallback_used, ...
    fully_vignetted, status_text)

    info = struct();
    info.sampling_mode = string(sampling_mode);
    info.used_u_low = used_u_low;
    info.used_u_high = used_u_high;
    info.used_u_center = used_u_center;
    info.allowed_u_low = allowed_u_low;
    info.allowed_u_high = allowed_u_high;
    info.lower_limiter_element_id = string(lower_id);
    info.upper_limiter_element_id = string(upper_id);
    info.fallback_used = logical(fallback_used);
    info.fully_vignetted = logical(fully_vignetted);
    info.status_text = string(status_text);
end
