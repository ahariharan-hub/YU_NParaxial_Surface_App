function bundle = nparaxial_trace_bundle_yu(rays, prescription, z_final)
%NPARAXIAL_TRACE_BUNDLE_YU Trace a table or matrix of y-u rays.

    if istable(rays)
        required = ["z0", "y0", "u0"];
        names = string(rays.Properties.VariableNames);
        for k = 1:numel(required)
            if ~ismember(required(k), names)
                error('Ray table must contain z0, y0, and u0 columns.');
            end
        end

        nRays = height(rays);
        if ismember("name", names)
            rayNames = string(rays.name);
        else
            rayNames = "ray_" + string((1:nRays).');
        end
        rayMatrix = [rays.z0, rays.y0, rays.u0];

    elseif isnumeric(rays)
        if size(rays, 2) ~= 3
            error('Numeric rays input must have columns [z0, y0, u0].');
        end
        nRays = size(rays, 1);
        rayNames = "ray_" + string((1:nRays).');
        rayMatrix = rays;

    else
        error('rays must be a table or numeric matrix.');
    end

    bundle(nRays, 1) = struct( ...
        'name', "", ...
        'ray_in', [], ...
        'res', [], ...
        'trc', false, ...
        'yf', NaN, ...
        'uf', NaN);

    for k = 1:nRays
        res = nparaxial_trace_ray_yu(rayMatrix(k, :), prescription, z_final);
        bundle(k).name = rayNames(k);
        bundle(k).ray_in = rayMatrix(k, :);
        bundle(k).res = res;
        bundle(k).trc = res.trc;
        bundle(k).yf = res.yf;
        bundle(k).uf = res.uf;
    end
end
