function diag = nparaxial_surface_vertex_scalar_validity_yu( ...
    y, u_in, n1, n2, R, u_out_paraxial, tol)
%NPARAXIAL_SURFACE_VERTEX_SCALAR_VALIDITY_YU Vertex-plane surface diagnostic.
%
% This is diagnostic only. It uses the paraxial event height at the vertex
% plane and the local spherical normal angle alpha = -asin(y/R). It does
% not perform true ray-sphere intersection and does not alter the paraxial
% trace result.

    if nargin < 6
        u_out_paraxial = [];
    end
    if nargin < 7 || isempty(tol)
        tol = 1e-12;
    end
    if ~isscalar(n1) || ~isscalar(n2) || ~isscalar(R) || ...
            ~isfinite(n1) || ~isfinite(n2) || ~isfinite(R) || ...
            n1 <= 0 || n2 <= 0 || R == 0
        error('n1, n2, and finite nonzero R must be scalar values.');
    end
    if ~isscalar(tol) || ~isfinite(tol) || tol <= 0
        error('tol must be a positive finite scalar.');
    end

    n = max(numel(y), numel(u_in));
    if ~isempty(u_out_paraxial)
        n = max(n, numel(u_out_paraxial));
    end
    y = expand_double_local(y, n);
    u_in = expand_double_local(u_in, n);
    if isempty(u_out_paraxial)
        u_out_paraxial = (n1/n2).*u_in + ((n1 - n2)/(n2*R)).*y;
    else
        u_out_paraxial = expand_double_local(u_out_paraxial, n);
    end

    normalArg = y ./ R;
    normalInvalid = ~isfinite(normalArg) | abs(normalArg) > 1 + tol;
    normalValid = ~normalInvalid;
    normalClamped = NaN(size(normalArg));
    normalClamped(normalValid) = min(max(normalArg(normalValid), -1), 1);
    surfaceClamp = normalValid & abs(normalArg) > 1;
    alpha = NaN(size(normalArg));
    alpha(normalValid) = -asin(normalClamped(normalValid));
    alphaParaxial = -normalArg;
    incidence = u_in - alpha;
    incidenceParaxial = u_in - alphaParaxial;

    ratio = n1/n2;
    snellArg = NaN(size(normalArg));
    snellArg(normalValid) = ratio .* sin(incidence(normalValid));
    tirFlag = normalValid & abs(snellArg) > 1 + tol;
    snellValid = normalValid & ~tirFlag & isfinite(snellArg);
    snellClamped = NaN(size(normalArg));
    snellClamped(snellValid) = min(max(snellArg(snellValid), -1), 1);
    snellClampFlag = snellValid & abs(snellArg) > 1;

    iPrime = NaN(size(normalArg));
    iPrime(snellValid) = asin(snellClamped(snellValid));
    uExact = NaN(size(normalArg));
    uExact(snellValid) = alpha(snellValid) + iPrime(snellValid);
    deltaU = uExact - u_out_paraxial;

    exactNonfinite = snellValid & ~isfinite(uExact);
    grazingNormal = normalValid & abs(normalClamped) >= 1 - sqrt(tol);
    invalidFlag = normalInvalid | exactNonfinite | grazingNormal;

    inMetrics = nparaxial_angle_validity_metrics_yu(u_in, tol);
    outMetrics = nparaxial_angle_validity_metrics_yu(u_out_paraxial, tol);
    exactMetrics = nparaxial_angle_validity_metrics_yu(uExact, tol);
    incidenceMetrics = nparaxial_angle_validity_metrics_yu(incidence, tol);

    inLevels = nparaxial_validity_warning_level_yu( ...
        u_in, inMetrics.relative_tan_error, tirFlag, invalidFlag);
    outLevels = nparaxial_validity_warning_level_yu( ...
        u_out_paraxial, outMetrics.relative_tan_error, tirFlag, invalidFlag);
    exactLevels = nparaxial_validity_warning_level_yu( ...
        uExact, exactMetrics.relative_tan_error, tirFlag, invalidFlag);
    incidenceLevels = nparaxial_validity_warning_level_yu( ...
        incidence, incidenceMetrics.relative_tan_error, tirFlag, invalidFlag);
    levels = max_level_local( ...
        max_level_local(inLevels, outLevels), ...
        max_level_local(exactLevels, incidenceLevels));

    notes = repmat( ...
        "Vertex-plane scalar Snell comparison; no true ray-sphere intersection.", ...
        numel(y), 1);
    notes(normalInvalid) = ...
        "Invalid vertex-plane spherical normal: abs(y/R) > 1 + tol.";
    notes(surfaceClamp & ~normalInvalid) = ...
        "Normal argument clamped within tolerance for asin.";
    notes(tirFlag) = ...
        "Vertex-plane scalar Snell diagnostic flags TIR; paraxial trace unchanged.";
    notes(grazingNormal & ~normalInvalid & ~tirFlag) = ...
        "Surface normal is near grazing at abs(y/R) ~= 1; warning forced severe.";
    notes(snellClampFlag & ~tirFlag) = ...
        "Snell argument clamped within tolerance for asin.";

    diag = struct();
    diag.surface_alpha_vertex = alpha;
    diag.surface_alpha_paraxial = alphaParaxial;
    diag.surface_incidence_exact = incidence;
    diag.surface_incidence_paraxial = incidenceParaxial;
    diag.surface_normal_argument = normalArg;
    diag.surface_normal_argument_clamped = normalClamped;
    diag.surface_sasin_clamped_flag = surfaceClamp;
    diag.surface_snell_argument = snellArg;
    diag.surface_snell_argument_clamped = snellClamped;
    diag.snell_clamped_flag = snellClampFlag;
    diag.u_out_exact_vertex = uExact;
    diag.delta_u_vertex_scalar = deltaU;
    diag.invalid_surface_normal_flag = normalInvalid;
    diag.tir_flag = tirFlag;
    diag.warning_level = levels;
    diag.note = notes;
end


function values = expand_double_local(values, n)
    values = double(values(:));
    if isempty(values)
        return
    end
    if isscalar(values) && n > 1
        values = repmat(values, n, 1);
    end
    if numel(values) ~= n
        error('Inputs must be scalar or match numel(y).');
    end
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
