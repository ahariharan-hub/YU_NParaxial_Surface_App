function metrics = nparaxial_angle_validity_metrics_yu(u, tol)
%NPARAXIAL_ANGLE_VALIDITY_METRICS_YU Small-angle diagnostic metrics.
%
% The y-u app convention treats u as the paraxial ray angle in radians.
% These quantities are diagnostic comparisons only; they do not alter the
% paraxial trace.

    if nargin < 2 || isempty(tol)
        tol = 1e-12;
    end
    if ~isscalar(tol) || ~isfinite(tol) || tol <= 0
        error('tol must be a positive finite scalar.');
    end

    u = double(u(:));
    tanU = tan(u);
    sinU = sin(u);
    cosU = cos(u);

    tanMinusU = tanU - u;
    sinMinusU = sinU - u;
    cosMinus1 = cosU - 1;

    relativeTan = abs(tanMinusU) ./ max(abs(tanU), tol);
    relativeSin = abs(sinMinusU) ./ max(abs(sinU), tol);

    numericValid = isfinite(u) & isfinite(tanU) & isfinite(sinU) & ...
        isfinite(cosU) & isfinite(relativeTan) & isfinite(relativeSin);
    tanValid = numericValid & abs(cosU) > tol;
    sinValid = numericValid;

    metrics = table;
    metrics.u = u;
    metrics.angle_deg = u * 180/pi;
    metrics.tan_minus_u = tanMinusU;
    metrics.sin_minus_u = sinMinusU;
    metrics.cos_minus_1 = cosMinus1;
    metrics.relative_tan_error = relativeTan;
    metrics.relative_sin_error = relativeSin;
    metrics.numeric_valid = numericValid;
    metrics.tan_valid = tanValid;
    metrics.sin_valid = sinValid;
end
