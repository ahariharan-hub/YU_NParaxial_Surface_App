function diag = nparaxial_thinlens_validity_yu(y, u_in, f, tol)
%NPARAXIAL_THINLENS_VALIDITY_YU Thin-lens angle/deflection diagnostic.
%
% A thin lens has no unique exact Snell reference in this first-order app.
% This helper reports angle and paraxial deflection magnitudes only.

    if nargin < 4 || isempty(tol)
        tol = 1e-12;
    end
    if ~isscalar(f) || ~isfinite(f) || abs(f) <= tol
        error('f must be a finite nonzero scalar focal length.');
    end

    y = double(y(:));
    u_in = double(u_in(:));
    if isscalar(y) && numel(u_in) > 1
        y = repmat(y, numel(u_in), 1);
    elseif isscalar(u_in) && numel(y) > 1
        u_in = repmat(u_in, numel(y), 1);
    end
    if numel(y) ~= numel(u_in)
        error('y and u_in must be scalar or have matching sizes.');
    end

    deflection = -y ./ f;
    uOut = u_in + deflection;

    inMetrics = nparaxial_angle_validity_metrics_yu(u_in, tol);
    outMetrics = nparaxial_angle_validity_metrics_yu(uOut, tol);
    defMetrics = nparaxial_angle_validity_metrics_yu(deflection, tol);
    inLevels = nparaxial_validity_warning_level_yu( ...
        u_in, inMetrics.relative_tan_error, false, ~inMetrics.numeric_valid);
    outLevels = nparaxial_validity_warning_level_yu( ...
        uOut, outMetrics.relative_tan_error, false, ~outMetrics.numeric_valid);
    defLevels = nparaxial_validity_warning_level_yu( ...
        deflection, defMetrics.relative_tan_error, false, ...
        ~defMetrics.numeric_valid);

    diag = struct();
    diag.y = y;
    diag.f = f;
    diag.u_in = u_in;
    diag.deflection = deflection;
    diag.abs_deflection = abs(deflection);
    diag.u_out = uOut;
    diag.input_metrics = inMetrics;
    diag.output_metrics = outMetrics;
    diag.deflection_metrics = defMetrics;
    diag.warning_level = max_level_local(max_level_local(inLevels, outLevels), ...
        defLevels);
    diag.note = "Thin lens has no unique exact Snell reference; this diagnostic reports angle and deflection magnitude only.";
end


function levels = max_level_local(a, b)
    a = string(a(:));
    b = string(b(:));
    score = max(severity_local(a), severity_local(b));
    names = ["ok"; "notice"; "warning"; "severe"];
    levels = names(score + 1);
end


function score = severity_local(levels)
    levels = string(levels(:));
    score = zeros(numel(levels), 1);
    score(levels == "notice") = 1;
    score(levels == "warning") = 2;
    score(levels == "severe") = 3;
end
