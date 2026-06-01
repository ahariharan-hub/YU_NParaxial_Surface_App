function diag = nparaxial_surface_true_intersection_validity_yu( ...
    y0, u_in, n1, n2, R, u_out_paraxial, vertex_diag, tol)
%NPARAXIAL_SURFACE_TRUE_INTERSECTION_VALIDITY_YU Local hit diagnostic.
%
% This diagnostic solves one local ray-sphere intersection from the
% paraxial vertex-plane event state. The exact hit and exact scalar-Snell
% output are reported only as diagnostics and are not propagated downstream.

    if nargin < 6
        u_out_paraxial = [];
    end
    if nargin < 7
        vertex_diag = [];
    end
    if nargin < 8 || isempty(tol)
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

    n = max(numel(y0), numel(u_in));
    if ~isempty(u_out_paraxial)
        n = max(n, numel(u_out_paraxial));
    end
    y0 = expand_double_local(y0, n);
    u_in = expand_double_local(u_in, n);
    if isempty(u_out_paraxial)
        u_out_paraxial = (n1/n2).*u_in + ((n1 - n2)/(n2*R)).*y0;
    else
        u_out_paraxial = expand_double_local(u_out_paraxial, n);
    end

    if isempty(vertex_diag)
        vertex_diag = nparaxial_surface_vertex_scalar_validity_yu( ...
            y0, u_in, n1, n2, R, u_out_paraxial, tol);
    end
    vertexU = expand_double_local(vertex_diag.u_out_exact_vertex, n);

    sHit = NaN(n, 1);
    yHit = NaN(n, 1);
    existsFlag = false(n, 1);
    ambiguousFlag = false(n, 1);
    root1 = NaN(n, 1);
    root2 = NaN(n, 1);
    residual1 = NaN(n, 1);
    residual2 = NaN(n, 1);
    sagAtY0 = NaN(n, 1);
    hitMinusY0 = NaN(n, 1);
    hitMinusSag = NaN(n, 1);
    alphaHit = NaN(n, 1);
    incidenceHit = NaN(n, 1);
    snellArgHit = NaN(n, 1);
    snellArgHitClamped = NaN(n, 1);
    snellHitClampedFlag = false(n, 1);
    uOutExactHit = NaN(n, 1);
    deltaVsParaxial = NaN(n, 1);
    deltaVsVertex = NaN(n, 1);
    noIntersectionFlag = false(n, 1);
    invalidHitNormalFlag = false(n, 1);
    tirHitFlag = false(n, 1);
    warningLevel = strings(n, 1);
    notes = strings(n, 1);

    for k = 1:n
        [hit, rootDiag] = select_hit_local(y0(k), u_in(k), R, tol);
        root1(k) = rootDiag.root1;
        root2(k) = rootDiag.root2;
        residual1(k) = rootDiag.residual1;
        residual2(k) = rootDiag.residual2;
        sagAtY0(k) = sag_local(y0(k), R, tol);
        noIntersectionFlag(k) = rootDiag.no_intersection;
        ambiguousFlag(k) = rootDiag.ambiguous;
        existsFlag(k) = hit.exists;
        sHit(k) = hit.s;
        yHit(k) = hit.y;

        fragments = [
            "Local true-intersection spherical diagnostic only."
            "Exact hit and exact output angle are not propagated downstream."
            "Aperture clipping remains paraxial vertex-plane clipping."
            "No full exact ray trace is performed."
            ];

        if hit.exists
            hitMinusY0(k) = yHit(k) - y0(k);
            hitMinusSag(k) = sHit(k) - sagAtY0(k);
            normalArg = yHit(k)/R;
            invalidHitNormalFlag(k) = ~isfinite(normalArg) || ...
                abs(normalArg) > 1 + tol;
            if ~invalidHitNormalFlag(k)
                normalArgClamped = min(max(normalArg, -1), 1);
                alphaHit(k) = -asin(normalArgClamped);
                incidenceHit(k) = u_in(k) - alphaHit(k);
                snellArgHit(k) = (n1/n2)*sin(incidenceHit(k));
                tirHitFlag(k) = isfinite(snellArgHit(k)) && ...
                    abs(snellArgHit(k)) > 1 + tol;
                if isfinite(snellArgHit(k)) && ~tirHitFlag(k)
                    snellArgHitClamped(k) = min(max(snellArgHit(k), -1), 1);
                    snellHitClampedFlag(k) = abs(snellArgHit(k)) > 1;
                    iPrime = asin(snellArgHitClamped(k));
                    uOutExactHit(k) = alphaHit(k) + iPrime;
                    deltaVsParaxial(k) = uOutExactHit(k) - ...
                        u_out_paraxial(k);
                    deltaVsVertex(k) = uOutExactHit(k) - vertexU(k);
                end
            end
        end

        if rootDiag.no_intersection
            fragments(end+1, 1) = ...
                "No real branch-consistent ray-sphere intersection."; %#ok<AGROW>
        end
        if rootDiag.nonfinite
            fragments(end+1, 1) = ...
                "Intersection roots are nonfinite or numerically invalid."; %#ok<AGROW>
        end
        if rootDiag.ambiguous
            fragments(end+1, 1) = ...
                "Intersection root selection is ambiguous or tangent-like."; %#ok<AGROW>
        end
        if invalidHitNormalFlag(k)
            fragments(end+1, 1) = ...
                "Invalid hit normal: abs(y_hit/R) > 1 + tol."; %#ok<AGROW>
        end
        if tirHitFlag(k)
            fragments(end+1, 1) = ...
                "True-hit scalar Snell diagnostic flags TIR."; %#ok<AGROW>
        end
        if isfinite(snellArgHit(k)) && snellHitClampedFlag(k)
            fragments(end+1, 1) = ...
                "True-hit Snell argument clamped within tolerance for asin."; %#ok<AGROW>
        end
        if hit.exists && isfinite(yHit(k)/R) && abs(yHit(k)/R) >= ...
                1 - sqrt(tol)
            fragments(end+1, 1) = ...
                "Hit normal is near grazing at abs(y_hit/R) ~= 1."; %#ok<AGROW>
        end
        if hit.exists && ~isfinite(snellArgHit(k))
            fragments(end+1, 1) = ...
                "True-hit Snell argument is nonfinite."; %#ok<AGROW>
        end
        if hit.exists && ~tirHitFlag(k) && ~invalidHitNormalFlag(k) && ...
                ~isfinite(uOutExactHit(k))
            fragments(end+1, 1) = ...
                "True-hit exact scalar output is nonfinite."; %#ok<AGROW>
        end
        if hit.exists && abs(sHit(k)) > 0.1*abs(R)
            fragments(end+1, 1) = ...
                "True hit is far from the vertex plane."; %#ok<AGROW>
        end
        if isfinite(deltaVsParaxial(k)) && abs(deltaVsParaxial(k)) > 0.02
            fragments(end+1, 1) = ...
                "Large true-hit delta versus paraxial output."; %#ok<AGROW>
        end
        if isfinite(deltaVsVertex(k)) && abs(deltaVsVertex(k)) > 0.02
            fragments(end+1, 1) = ...
                "Large true-hit delta versus vertex-plane scalar output."; %#ok<AGROW>
        end

        severe = rootDiag.no_intersection || rootDiag.nonfinite || ...
            rootDiag.ambiguous || invalidHitNormalFlag(k) || ...
            tirHitFlag(k) || ~isfinite(snellArgHit(k)) || ...
            (hit.exists && ~tirHitFlag(k) && ~invalidHitNormalFlag(k) && ...
            ~isfinite(uOutExactHit(k)));
        warning = hit.exists && (abs(sHit(k)) > 0.1*abs(R) || ...
            (isfinite(yHit(k)/R) && abs(yHit(k)/R) >= 1 - sqrt(tol)) || ...
            (isfinite(deltaVsParaxial(k)) && abs(deltaVsParaxial(k)) > 0.02) || ...
            (isfinite(deltaVsVertex(k)) && abs(deltaVsVertex(k)) > 0.02));

        baseMetrics = nparaxial_angle_validity_metrics_yu( ...
            [u_in(k); u_out_paraxial(k); uOutExactHit(k); incidenceHit(k)], tol);
        baseLevel = max_level_array_local(nparaxial_validity_warning_level_yu( ...
            baseMetrics.u, baseMetrics.relative_tan_error, ...
            repmat(tirHitFlag(k), 4, 1), repmat(severe, 4, 1)));
        if severe
            warningLevel(k) = "severe";
        elseif warning && severity_local(baseLevel) < 2
            warningLevel(k) = "warning";
        else
            warningLevel(k) = baseLevel;
        end
        notes(k) = strjoin(cellstr(fragments), '; ');
    end

    diag = struct();
    diag.surface_intersection_s = sHit;
    diag.surface_intersection_y = yHit;
    diag.surface_intersection_exists = existsFlag;
    diag.surface_intersection_ambiguous_flag = ambiguousFlag;
    diag.surface_intersection_root1 = root1;
    diag.surface_intersection_root2 = root2;
    diag.surface_intersection_residual1 = residual1;
    diag.surface_intersection_residual2 = residual2;
    diag.surface_sag_at_y0 = sagAtY0;
    diag.surface_hit_minus_vertex_y = hitMinusY0;
    diag.surface_hit_minus_sag = hitMinusSag;
    diag.surface_alpha_hit = alphaHit;
    diag.surface_incidence_hit = incidenceHit;
    diag.surface_snell_argument_hit = snellArgHit;
    diag.surface_snell_argument_hit_clamped = snellArgHitClamped;
    diag.snell_hit_clamped_flag = snellHitClampedFlag;
    diag.u_out_exact_hit = uOutExactHit;
    diag.delta_u_exact_hit_vs_paraxial = deltaVsParaxial;
    diag.delta_u_hit_vs_vertex = deltaVsVertex;
    diag.no_intersection_flag = noIntersectionFlag;
    diag.invalid_hit_normal_flag = invalidHitNormalFlag;
    diag.tir_hit_flag = tirHitFlag;
    diag.warning_level = warningLevel;
    diag.note = notes;
end


function [hit, rootDiag] = select_hit_local(y0, uIn, R, tol)
    hit = struct('exists', false, 's', NaN, 'y', NaN);
    rootDiag = struct( ...
        'root1', NaN, 'root2', NaN, ...
        'residual1', NaN, 'residual2', NaN, ...
        'no_intersection', false, ...
        'ambiguous', false, ...
        'nonfinite', false);

    t = tan(uIn);
    if ~isfinite(y0) || ~isfinite(uIn) || ~isfinite(t)
        rootDiag.no_intersection = true;
        rootDiag.nonfinite = true;
        return
    end

    a = 1 + t^2;
    b = 2*(y0*t - R);
    c = y0^2;
    disc = b^2 - 4*a*c;
    scale = max([abs(b)^2, abs(4*a*c), 1]);
    if ~isfinite(a) || ~isfinite(b) || ~isfinite(c) || ~isfinite(disc)
        rootDiag.no_intersection = true;
        rootDiag.nonfinite = true;
        return
    end
    if disc < -tol*scale
        rootDiag.no_intersection = true;
        return
    end

    nearTangent = abs(disc) <= sqrt(tol)*scale;
    disc = max(disc, 0);
    sqrtDisc = sqrt(disc);
    if sqrtDisc == 0
        roots = [-b/(2*a); -b/(2*a)];
    else
        if b >= 0
            q = -0.5*(b + sqrtDisc);
        else
            q = -0.5*(b - sqrtDisc);
        end
        if q == 0
            roots = [(-b - sqrtDisc)/(2*a); (-b + sqrtDisc)/(2*a)];
        else
            roots = [q/a; c/q];
        end
    end

    rootDiag.root1 = roots(1);
    rootDiag.root2 = roots(2);
    residuals = branch_residuals_local(roots, y0, t, R, tol);
    rootDiag.residual1 = residuals(1);
    rootDiag.residual2 = residuals(2);

    finiteMask = isfinite(roots) & isfinite(residuals);
    if ~any(finiteMask)
        rootDiag.no_intersection = true;
        rootDiag.nonfinite = true;
        return
    end

    finiteIdx = find(finiteMask);
    finiteResiduals = residuals(finiteIdx);
    minResidual = min(finiteResiduals);
    tied = abs(finiteResiduals - minResidual) <= ...
        100*tol*max([1; abs(finiteResiduals(:))]);
    if sum(tied) > 1 || nearTangent
        rootDiag.ambiguous = true;
    end

    candidates = finiteIdx(tied);
    if isempty(candidates)
        candidates = finiteIdx(finiteResiduals == minResidual);
    end
    [~, closeIdx] = min(abs(roots(candidates)));
    selected = candidates(closeIdx);
    s = roots(selected);
    y = y0 + s*t;

    hit.exists = true;
    hit.s = s;
    hit.y = y;
end


function residuals = branch_residuals_local(roots, y0, t, R, tol)
    residuals = NaN(size(roots));
    for k = 1:numel(roots)
        s = roots(k);
        if ~isfinite(s)
            continue
        end
        yHit = y0 + s*t;
        sag = sag_local(yHit, R, tol);
        if isfinite(sag)
            residuals(k) = abs(s - sag);
        end
    end
end


function sag = sag_local(y, R, tol)
    arg = R^2 - y^2;
    scale = max(R^2, 1);
    if ~isfinite(arg) || arg < -tol*scale
        sag = NaN;
        return
    end
    arg = max(arg, 0);
    sag = R - sign(R)*sqrt(arg);
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
        error('Inputs must be scalar or match the expanded input length.');
    end
end


function level = max_level_array_local(levels)
    levels = string(levels(:));
    score = max(severity_local(levels));
    names = ["ok"; "notice"; "warning"; "severe"];
    level = names(score + 1);
end


function score = severity_local(levels)
    levels = string(levels(:));
    score = zeros(numel(levels), 1);
    score(levels == "notice") = 1;
    score(levels == "warning") = 2;
    score(levels == "severe") = 3;
end
