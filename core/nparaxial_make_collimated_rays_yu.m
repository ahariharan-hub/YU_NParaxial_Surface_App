function rays = nparaxial_make_collimated_rays_yu( ...
    launch_z, y0, field_angle_rad, sampling_mode, status_text)
%NPARAXIAL_MAKE_COLLIMATED_RAYS_YU Build finite collimated launch rays.
%
% This helper is for object-at-infinity cases. It keeps launch coordinates
% finite and leaves the low-level trace engine wavelength-independent.

    if nargin < 3 || isempty(field_angle_rad)
        field_angle_rad = 0;
    end
    if nargin < 4 || strlength(string(sampling_mode)) == 0
        sampling_mode = "Collimated source";
    end
    if nargin < 5 || strlength(string(status_text)) == 0
        status_text = "Collimated source from finite launch plane.";
    end

    validate_inputs_local(launch_z, y0, field_angle_rad);
    y0 = double(y0(:));
    n = numel(y0);
    names = collimated_ray_names_local(n);
    u0 = repmat(double(field_angle_rad), n, 1);
    yFraction = sample_fraction_local(y0);

    rays = table;
    rays.ray_name = string(names(:));
    rays.name = rays.ray_name;
    rays.z0 = repmat(double(launch_z), n, 1);
    rays.y0 = y0;
    rays.u0 = u0;
    rays.sampling_mode = repmat(string(sampling_mode), n, 1);
    rays.u_low = repmat(double(field_angle_rad), n, 1);
    rays.u_high = repmat(double(field_angle_rad), n, 1);
    rays.u_center = repmat(double(field_angle_rad), n, 1);
    rays.u_fraction = yFraction;
    rays.lower_limiter_element_id = repmat("", n, 1);
    rays.upper_limiter_element_id = repmat("", n, 1);
    rays.fallback_used = false(n, 1);
    rays.fully_vignetted = false(n, 1);
    rays.status_text = repmat(string(status_text), n, 1);
    rays.z_target = NaN(n, 1);
    rays.y_target = NaN(n, 1);
    rays.source_mode = repmat("collimated", n, 1);
    rays.launch_y = y0;
    rays.field_angle_rad = u0;

    rays.Properties.UserData = struct( ...
        'sampling_mode', string(sampling_mode), ...
        'used_u_low', double(field_angle_rad), ...
        'used_u_high', double(field_angle_rad), ...
        'used_u_center', double(field_angle_rad), ...
        'allowed_u_low', double(field_angle_rad), ...
        'allowed_u_high', double(field_angle_rad), ...
        'lower_limiter_element_id', "", ...
        'upper_limiter_element_id', "", ...
        'fallback_used', false, ...
        'fully_vignetted', false, ...
        'status_text', string(status_text));
end


function validate_inputs_local(launch_z, y0, field_angle_rad)
    if ~isscalar(launch_z) || ~isfinite(launch_z)
        error('launch_z must be a finite scalar value.');
    end
    y0 = double(y0(:));
    if isempty(y0) || any(~isfinite(y0))
        error('y0 must contain finite launch heights.');
    end
    if ~isscalar(field_angle_rad) || ~isfinite(field_angle_rad)
        error('field_angle_rad must be a finite scalar value.');
    end
end


function names = collimated_ray_names_local(n)
    names = "collimated_" + string((1:n).');
    if n == 1
        names(1) = "chief";
        return
    end

    names(1) = "lower_marginal";
    names(end) = "upper_marginal";
    mid = round((n + 1)/2);
    names(mid) = "chief";
end


function yFraction = sample_fraction_local(y0)
    n = numel(y0);
    if n == 1
        yFraction = 0.5;
        return
    end

    span = max(y0) - min(y0);
    if span <= 0
        yFraction = linspace(0, 1, n).';
    else
        yFraction = (y0 - min(y0))./span;
    end
end
