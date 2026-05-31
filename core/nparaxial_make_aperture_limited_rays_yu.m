function rays = nparaxial_make_aperture_limited_rays_yu( ...
    prescription, z_obj, y_obj, n_rays, manual_u_max, tol, z_end)
%NPARAXIAL_MAKE_APERTURE_LIMITED_RAYS_YU Sample admitted launch slopes.
%
% This helper reuses nparaxial_vignetting_intervals_yu. It does not change
% the paraxial tracing model and does not assert that admitted rays are
% within the paraxial-valid regime.

    if nargin < 6 || isempty(tol)
        tol = 1e-12;
    end
    if nargin < 7 || isempty(z_end)
        z_end = Inf;
    end

    validate_inputs_local(z_obj, y_obj, n_rays, manual_u_max, tol, z_end);
    n_rays = normalize_ray_count_local(n_rays);

    vig = nparaxial_vignetting_intervals_yu( ...
        prescription, z_obj, y_obj, z_end, tol);

    if vig.fully_vignetted
        statusText = "Selected field is fully vignetted; no transmitted aperture-limited ray fan.";
        rays = empty_ray_table_local(z_obj, y_obj, statusText);
        rays.Properties.UserData = info_local( ...
            "Aperture-limited admitted cone", NaN, NaN, NaN, ...
            vig.u_low, vig.u_high, vig.lower_bound_element_id, ...
            vig.upper_bound_element_id, false, true, statusText);
        return
    end

    if ~isfinite(vig.u_low) || ~isfinite(vig.u_high)
        statusText = "Aperture-limited interval is unbounded; using manual fixed-angle fan.";
        rays = nparaxial_make_manual_fan_rays_yu( ...
            z_obj, y_obj, n_rays, manual_u_max, ...
            "Aperture-limited admitted cone", statusText);
        rays.sampling_mode(:) = "Aperture-limited admitted cone";
        rays.fallback_used(:) = true;
        rays.lower_limiter_element_id(:) = vig.lower_bound_element_id;
        rays.upper_limiter_element_id(:) = vig.upper_bound_element_id;
        rays.Properties.UserData = info_local( ...
            "Aperture-limited admitted cone", -manual_u_max, manual_u_max, ...
            0, vig.u_low, vig.u_high, vig.lower_bound_element_id, ...
            vig.upper_bound_element_id, true, false, statusText);
        return
    end

    u0 = linspace(vig.u_low, vig.u_high, n_rays).';
    uFraction = linspace(0, 1, n_rays).';
    uCenter = 0.5*(vig.u_low + vig.u_high);
    names = aperture_limited_names_local(n_rays);
    statusText = "Aperture-limited admitted cone.";

    rays = ray_table_local( ...
        names, z_obj, y_obj, u0, "Aperture-limited admitted cone", ...
        vig.u_low, vig.u_high, uCenter, uFraction, ...
        vig.lower_bound_element_id, vig.upper_bound_element_id, ...
        false, false, statusText);
    rays.Properties.UserData = info_local( ...
        "Aperture-limited admitted cone", vig.u_low, vig.u_high, ...
        uCenter, vig.u_low, vig.u_high, vig.lower_bound_element_id, ...
        vig.upper_bound_element_id, false, false, statusText);
end


function validate_inputs_local(z_obj, y_obj, n_rays, manual_u_max, tol, z_end)
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
    if ~isscalar(tol) || ~isfinite(tol) || tol <= 0
        error('tol must be a positive finite scalar value.');
    end
    if ~isscalar(z_end) || isnan(z_end)
        error('z_end must be a scalar value or Inf.');
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


function names = aperture_limited_names_local(n_rays)
    names = "aperture_limited_" + string((1:n_rays).');
    mid = (n_rays + 1)/2;
    names(1) = "aperture_limited_lower";
    names(mid) = "aperture_limited_center";
    names(end) = "aperture_limited_upper";
end


function rays = empty_ray_table_local(z_obj, y_obj, status_text)
    rays = ray_table_local( ...
        strings(0, 1), z_obj, y_obj, zeros(0, 1), ...
        "Aperture-limited admitted cone", NaN, NaN, NaN, zeros(0, 1), ...
        "", "", false, true, status_text);
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
