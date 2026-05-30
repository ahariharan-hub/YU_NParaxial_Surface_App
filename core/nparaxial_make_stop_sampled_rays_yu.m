function rays = nparaxial_make_stop_sampled_rays_yu( ...
    prescription, z_obj, y_obj, z_stop, a_stop, num_pupil_rays)
%NPARAXIAL_MAKE_STOP_SAMPLED_RAYS_YU Generate rays aimed at a stop plane.

    if nargin < 6 || isempty(num_pupil_rays)
        num_pupil_rays = 21;
    end

    if ~isscalar(num_pupil_rays) || ~isfinite(num_pupil_rays)
        error('num_pupil_rays must be finite scalar.');
    end
    num_pupil_rays = round(num_pupil_rays);
    if num_pupil_rays < 3
        error('num_pupil_rays must be at least 3.');
    end
    if mod(num_pupil_rays, 2) == 0
        num_pupil_rays = num_pupil_rays + 1;
    end

    if ~isscalar(z_obj) || ~isfinite(z_obj) || ...
            ~isscalar(y_obj) || ~isfinite(y_obj) || ...
            ~isscalar(z_stop) || ~isfinite(z_stop) || ...
            ~isscalar(a_stop) || ~isfinite(a_stop) || a_stop <= 0
        error('Object and stop inputs must be finite scalar values.');
    end
    if z_stop <= z_obj
        error('z_stop must be after z_obj.');
    end

    y_targets = linspace(-a_stop, a_stop, num_pupil_rays).';
    M_stop = nparaxial_system_matrix_yu(prescription, z_obj, z_stop);
    A = M_stop(1, 1);
    B = M_stop(1, 2);

    if abs(B) < 1e-12
        error('Cannot solve launch slopes because B to the stop is near zero.');
    end

    u0 = (y_targets - A*y_obj) ./ B;
    names = pupil_ray_names_local(y_targets, a_stop);

    rays = table;
    rays.name = names;
    rays.z0 = repmat(z_obj, num_pupil_rays, 1);
    rays.y0 = repmat(y_obj, num_pupil_rays, 1);
    rays.u0 = u0;
    rays.z_target = repmat(z_stop, num_pupil_rays, 1);
    rays.y_target = y_targets;
end


function names = pupil_ray_names_local(y_targets, a_stop)
    nRays = numel(y_targets);
    names = strings(nRays, 1);
    tol = max(1e-12, 1e-12*abs(a_stop));
    for k = 1:nRays
        if abs(y_targets(k) + a_stop) <= tol
            names(k) = "lower_marginal";
        elseif abs(y_targets(k) - a_stop) <= tol
            names(k) = "upper_marginal";
        elseif abs(y_targets(k)) <= tol
            names(k) = "chief";
        else
            names(k) = "pupil_" + string(k);
        end
    end
end
