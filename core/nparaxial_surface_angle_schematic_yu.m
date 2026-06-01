function schematic = nparaxial_surface_angle_schematic_yu(y, u, R, tol)
%NPARAXIAL_SURFACE_ANGLE_SCHEMATIC_YU Vertex-plane surface-angle values.
%
% Uses the app convention u = paraxial ray angle in radians and the
% finite-radius surface normal convention alpha = -asin(y/R).

    if nargin < 4 || isempty(tol)
        tol = 1e-12;
    end
    if ~isscalar(R) || ~isfinite(R) || R == 0
        error('R must be a finite nonzero scalar.');
    end
    if ~isscalar(tol) || ~isfinite(tol) || tol <= 0
        tol = 1e-12;
    end

    n = max(numel(y), numel(u));
    y = expand_double_local(y, n);
    u = expand_double_local(u, n);

    normalArg = y ./ R;
    normalArgClamped = min(max(normalArg, -1), 1);
    valid = isfinite(normalArg) & abs(normalArg) <= 1 + tol;
    alpha = NaN(n, 1);
    theta = NaN(n, 1);
    alpha(valid) = -asin(normalArgClamped(valid));
    theta(valid) = u(valid) - alpha(valid);

    note = strings(n, 1);
    note(valid) = "Vertex-plane surface-angle schematic.";
    note(~valid) = "Invalid schematic: abs(y/R) > 1 + tol or nonfinite input.";

    schematic = table;
    schematic.y = y;
    schematic.u = u;
    schematic.R = repmat(double(R), n, 1);
    schematic.normal_argument = normalArg;
    schematic.alpha = alpha;
    schematic.theta = theta;
    schematic.u_deg = u*180/pi;
    schematic.alpha_deg = alpha*180/pi;
    schematic.theta_deg = theta*180/pi;
    schematic.valid_schematic = valid;
    schematic.note = note;
end


function values = expand_double_local(values, n)
    values = double(values(:));
    if isscalar(values) && n > 1
        values = repmat(values, n, 1);
    end
    if numel(values) ~= n
        error('Inputs must be scalar or match the expanded input length.');
    end
end
