function diag = nparaxial_plane_refraction_validity_yu(n1, n2, u_in, tol)
%NPARAXIAL_PLANE_REFRACTION_VALIDITY_YU Plane-interface Snell diagnostic.
%
% This is diagnostic only. Total internal reflection does not alter the
% paraxial trace result. Values slightly outside [-1, 1] within tolerance
% are clamped for numerical robustness; abs(arg) > 1 + tol is reported as
% total internal reflection.

    if nargin < 4 || isempty(tol)
        tol = 1e-12;
    end
    if ~isscalar(n1) || ~isscalar(n2) || ~isfinite(n1) || ...
            ~isfinite(n2) || n1 <= 0 || n2 <= 0
        error('n1 and n2 must be positive finite scalar values.');
    end

    u_in = double(u_in(:));
    ratio = n1/n2;
    uOutParaxial = ratio * u_in;
    arg = ratio * sin(u_in);
    tirFlag = abs(arg) > 1 + tol;

    uOutExact = NaN(size(u_in));
    valid = ~tirFlag & isfinite(arg);
    argClamped = NaN(size(u_in));
    argClamped(valid) = min(max(arg(valid), -1), 1);
    uOutExact(valid) = asin(argClamped(valid));
    deltaU = uOutExact - uOutParaxial;

    inMetrics = nparaxial_angle_validity_metrics_yu(u_in, tol);
    outMetrics = nparaxial_angle_validity_metrics_yu(uOutParaxial, tol);
    inLevels = nparaxial_validity_warning_level_yu( ...
        u_in, inMetrics.relative_tan_error, tirFlag, ~inMetrics.numeric_valid);
    outLevels = nparaxial_validity_warning_level_yu( ...
        uOutParaxial, outMetrics.relative_tan_error, tirFlag, ...
        ~outMetrics.numeric_valid);
    levels = max_level_local(inLevels, outLevels);

    diag = struct();
    diag.n1 = n1;
    diag.n2 = n2;
    diag.u_in = u_in;
    diag.u_out_paraxial = uOutParaxial;
    diag.snell_argument = arg;
    diag.snell_argument_clamped = argClamped;
    diag.u_out_exact = uOutExact;
    diag.delta_u = deltaU;
    diag.tir_flag = tirFlag;
    diag.warning_level = levels;
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
