function eventTable = nparaxial_event_validity_yu(bundleSet, tol)
%NPARAXIAL_EVENT_VALIDITY_YU Build per-event paraxial-validity diagnostics.
%
% Diagnostics are reported only for events that appear in the traced ray
% histories. Downstream events after aperture blocking are not fabricated.

    if nargin < 2 || isempty(tol)
        tol = 1e-12;
    end

    eventTable = empty_event_table_local();

    for q = 1:numel(bundleSet)
        if ~isfield(bundleSet(q), 'bundle')
            continue
        end
        bundle = bundleSet(q).bundle;
        fieldId = field_index_local(bundleSet(q), q);
        for r = 1:numel(bundle)
            if ~isfield(bundle(r), 'res') || isempty(bundle(r).res) || ...
                    ~istable(bundle(r).res.events)
                continue
            end
            events = bundle(r).res.events;
            for k = 1:height(events)
                row = event_row_local(string(bundle(r).name), fieldId, ...
                    events(k, :), tol);
                eventTable = [eventTable; row]; %#ok<AGROW>
            end
        end
    end
end


function row = event_row_local(rayName, fieldId, ev, tol)
    uBefore = ev.u_before(1);
    uAfter = ev.u_after(1);
    if ~isfinite(uAfter)
        uAfterForMetrics = uBefore;
    else
        uAfterForMetrics = uAfter;
    end

    inMetrics = nparaxial_angle_validity_metrics_yu(uBefore, tol);
    outMetrics = nparaxial_angle_validity_metrics_yu(uAfterForMetrics, tol);
    inLevel = nparaxial_validity_warning_level_yu( ...
        uBefore, inMetrics.relative_tan_error, false, ...
        ~inMetrics.numeric_valid);
    outLevel = nparaxial_validity_warning_level_yu( ...
        uAfterForMetrics, outMetrics.relative_tan_error, false, ...
        ~outMetrics.numeric_valid);

    diagnosticType = "angle_only";
    deltaU = NaN;
    tirFlag = false;
    thinlensDeflection = NaN;
    absThinlensDeflection = NaN;
    surfaceAlphaVertex = NaN;
    surfaceAlphaParaxial = NaN;
    surfaceIncidenceExact = NaN;
    surfaceIncidenceParaxial = NaN;
    surfaceNormalArgument = NaN;
    surfaceNormalArgumentClamped = NaN;
    surfaceSasinClampedFlag = false;
    surfaceSnellArgument = NaN;
    surfaceSnellArgumentClamped = NaN;
    snellClampedFlag = false;
    uOutExactVertex = NaN;
    deltaUVertexScalar = NaN;
    invalidSurfaceNormalFlag = false;
    surfaceIntersectionS = NaN;
    surfaceIntersectionY = NaN;
    surfaceIntersectionExists = false;
    surfaceIntersectionAmbiguousFlag = false;
    surfaceIntersectionRoot1 = NaN;
    surfaceIntersectionRoot2 = NaN;
    surfaceIntersectionResidual1 = NaN;
    surfaceIntersectionResidual2 = NaN;
    surfaceSagAtY0 = NaN;
    surfaceHitMinusVertexY = NaN;
    surfaceHitMinusSag = NaN;
    surfaceAlphaHit = NaN;
    surfaceIncidenceHit = NaN;
    surfaceSnellArgumentHit = NaN;
    surfaceSnellArgumentHitClamped = NaN;
    snellHitClampedFlag = false;
    uOutExactHit = NaN;
    deltaUExactHitVsParaxial = NaN;
    deltaUHitVsVertex = NaN;
    noIntersectionFlag = false;
    invalidHitNormalFlag = false;
    tirHitFlag = false;
    note = "";
    warningLevel = max_level_local(inLevel, outLevel);

    if ~ev.passed_aperture(1)
        diagnosticType = "blocked_at_aperture";
        note = "Ray stopped at this aperture; downstream validity rows are not fabricated.";
        uAfter = NaN;
        warningLevel = inLevel;
    else
        switch string(ev.type(1))
            case "thinlens"
                lens = nparaxial_thinlens_validity_yu( ...
                    ev.y_before(1), uBefore, ev.focal_length(1), tol);
                diagnosticType = "thinlens_deflection";
                thinlensDeflection = lens.deflection(1);
                absThinlensDeflection = lens.abs_deflection(1);
                warningLevel = lens.warning_level(1);
                note = lens.note;

            case "surface"
                R = ev.radius_R(1);
                nBefore = ev.n_before(1);
                nAfter = ev.n_after(1);
                if isinf(R) || abs(1/R) <= tol
                    if abs(nAfter - nBefore) > tol
                        plane = nparaxial_plane_refraction_validity_yu( ...
                            nBefore, nAfter, uBefore, tol);
                        diagnosticType = "plane_refraction";
                        deltaU = plane.delta_u(1);
                        tirFlag = plane.tir_flag(1);
                        warningLevel = plane.warning_level(1);
                        note = "Plane refraction exact scalar Snell comparison is diagnostic only.";
                    else
                        diagnosticType = "plane_surface_no_refraction";
                        note = "Plane surface with unchanged medium; angle metrics only.";
                    end
                else
                    surface = nparaxial_surface_vertex_scalar_validity_yu( ...
                        ev.y_before(1), uBefore, nBefore, nAfter, R, ...
                        uAfter, tol);
                    hit = nparaxial_surface_true_intersection_validity_yu( ...
                        ev.y_before(1), uBefore, nBefore, nAfter, R, ...
                        uAfter, surface, tol);
                    diagnosticType = "spherical_true_intersection_local";
                    surfaceAlphaVertex = surface.surface_alpha_vertex(1);
                    surfaceAlphaParaxial = surface.surface_alpha_paraxial(1);
                    surfaceIncidenceExact = ...
                        surface.surface_incidence_exact(1);
                    surfaceIncidenceParaxial = ...
                        surface.surface_incidence_paraxial(1);
                    surfaceNormalArgument = ...
                        surface.surface_normal_argument(1);
                    surfaceNormalArgumentClamped = ...
                        surface.surface_normal_argument_clamped(1);
                    surfaceSasinClampedFlag = ...
                        surface.surface_sasin_clamped_flag(1);
                    surfaceSnellArgument = surface.surface_snell_argument(1);
                    surfaceSnellArgumentClamped = ...
                        surface.surface_snell_argument_clamped(1);
                    snellClampedFlag = surface.snell_clamped_flag(1);
                    uOutExactVertex = surface.u_out_exact_vertex(1);
                    deltaUVertexScalar = surface.delta_u_vertex_scalar(1);
                    invalidSurfaceNormalFlag = ...
                        surface.invalid_surface_normal_flag(1);
                    surfaceIntersectionS = hit.surface_intersection_s(1);
                    surfaceIntersectionY = hit.surface_intersection_y(1);
                    surfaceIntersectionExists = ...
                        hit.surface_intersection_exists(1);
                    surfaceIntersectionAmbiguousFlag = ...
                        hit.surface_intersection_ambiguous_flag(1);
                    surfaceIntersectionRoot1 = ...
                        hit.surface_intersection_root1(1);
                    surfaceIntersectionRoot2 = ...
                        hit.surface_intersection_root2(1);
                    surfaceIntersectionResidual1 = ...
                        hit.surface_intersection_residual1(1);
                    surfaceIntersectionResidual2 = ...
                        hit.surface_intersection_residual2(1);
                    surfaceSagAtY0 = hit.surface_sag_at_y0(1);
                    surfaceHitMinusVertexY = ...
                        hit.surface_hit_minus_vertex_y(1);
                    surfaceHitMinusSag = hit.surface_hit_minus_sag(1);
                    surfaceAlphaHit = hit.surface_alpha_hit(1);
                    surfaceIncidenceHit = hit.surface_incidence_hit(1);
                    surfaceSnellArgumentHit = ...
                        hit.surface_snell_argument_hit(1);
                    surfaceSnellArgumentHitClamped = ...
                        hit.surface_snell_argument_hit_clamped(1);
                    snellHitClampedFlag = hit.snell_hit_clamped_flag(1);
                    uOutExactHit = hit.u_out_exact_hit(1);
                    deltaUExactHitVsParaxial = ...
                        hit.delta_u_exact_hit_vs_paraxial(1);
                    deltaUHitVsVertex = hit.delta_u_hit_vs_vertex(1);
                    noIntersectionFlag = hit.no_intersection_flag(1);
                    invalidHitNormalFlag = hit.invalid_hit_normal_flag(1);
                    tirHitFlag = hit.tir_hit_flag(1);
                    deltaU = deltaUExactHitVsParaxial;
                    tirFlag = surface.tir_flag(1) || tirHitFlag;
                    warningLevel = max_level_local( ...
                        surface.warning_level(1), hit.warning_level(1));
                    note = surface.note(1) + " " + hit.note(1);
                end

            case {"stop", "dummy"}
                diagnosticType = "identity_event";
                note = "Stop and dummy events do not refract; angle metrics only.";

            otherwise
                diagnosticType = "unknown_event";
                note = "Unknown event type; angle metrics only.";
        end
    end

    row = table;
    row.ray_name = rayName;
    row.field_index = fieldId;
    row.event_index = ev.index(1);
    row.element_id = string(ev.element_id(1));
    row.type = string(ev.type(1));
    row.z = ev.z(1);
    row.y_before = ev.y_before(1);
    row.u_before = uBefore;
    row.u_after_paraxial = uAfter;
    row.n_before = ev.n_before(1);
    row.n_after = ev.n_after(1);
    row.diagnostic_type = diagnosticType;
    row.angle_in_deg = inMetrics.angle_deg(1);
    if isfinite(uAfter)
        row.angle_out_deg = outMetrics.angle_deg(1);
    else
        row.angle_out_deg = NaN;
    end
    row.delta_u = deltaU;
    row.tir_flag = tirFlag;
    row.thinlens_deflection = thinlensDeflection;
    row.abs_thinlens_deflection = absThinlensDeflection;
    row.surface_alpha_vertex = surfaceAlphaVertex;
    row.surface_alpha_paraxial = surfaceAlphaParaxial;
    row.surface_incidence_exact = surfaceIncidenceExact;
    row.surface_incidence_paraxial = surfaceIncidenceParaxial;
    row.surface_normal_argument = surfaceNormalArgument;
    row.surface_normal_argument_clamped = surfaceNormalArgumentClamped;
    row.surface_sasin_clamped_flag = surfaceSasinClampedFlag;
    row.surface_snell_argument = surfaceSnellArgument;
    row.surface_snell_argument_clamped = surfaceSnellArgumentClamped;
    row.snell_clamped_flag = snellClampedFlag;
    row.u_out_exact_vertex = uOutExactVertex;
    row.delta_u_vertex_scalar = deltaUVertexScalar;
    row.invalid_surface_normal_flag = invalidSurfaceNormalFlag;
    row.surface_intersection_s = surfaceIntersectionS;
    row.surface_intersection_y = surfaceIntersectionY;
    row.surface_intersection_exists = surfaceIntersectionExists;
    row.surface_intersection_ambiguous_flag = ...
        surfaceIntersectionAmbiguousFlag;
    row.surface_intersection_root1 = surfaceIntersectionRoot1;
    row.surface_intersection_root2 = surfaceIntersectionRoot2;
    row.surface_intersection_residual1 = surfaceIntersectionResidual1;
    row.surface_intersection_residual2 = surfaceIntersectionResidual2;
    row.surface_sag_at_y0 = surfaceSagAtY0;
    row.surface_hit_minus_vertex_y = surfaceHitMinusVertexY;
    row.surface_hit_minus_sag = surfaceHitMinusSag;
    row.surface_alpha_hit = surfaceAlphaHit;
    row.surface_incidence_hit = surfaceIncidenceHit;
    row.surface_snell_argument_hit = surfaceSnellArgumentHit;
    row.surface_snell_argument_hit_clamped = surfaceSnellArgumentHitClamped;
    row.snell_hit_clamped_flag = snellHitClampedFlag;
    row.u_out_exact_hit = uOutExactHit;
    row.delta_u_exact_hit_vs_paraxial = deltaUExactHitVsParaxial;
    row.delta_u_hit_vs_vertex = deltaUHitVsVertex;
    row.no_intersection_flag = noIntersectionFlag;
    row.invalid_hit_normal_flag = invalidHitNormalFlag;
    row.tir_hit_flag = tirHitFlag;
    row.warning_level = warningLevel;
    row.note = string(note);
end


function T = empty_event_table_local()
    T = table;
    T.ray_name = strings(0, 1);
    T.field_index = zeros(0, 1);
    T.event_index = zeros(0, 1);
    T.element_id = strings(0, 1);
    T.type = strings(0, 1);
    T.z = zeros(0, 1);
    T.y_before = zeros(0, 1);
    T.u_before = zeros(0, 1);
    T.u_after_paraxial = zeros(0, 1);
    T.n_before = zeros(0, 1);
    T.n_after = zeros(0, 1);
    T.diagnostic_type = strings(0, 1);
    T.angle_in_deg = zeros(0, 1);
    T.angle_out_deg = zeros(0, 1);
    T.delta_u = zeros(0, 1);
    T.tir_flag = false(0, 1);
    T.thinlens_deflection = zeros(0, 1);
    T.abs_thinlens_deflection = zeros(0, 1);
    T.surface_alpha_vertex = zeros(0, 1);
    T.surface_alpha_paraxial = zeros(0, 1);
    T.surface_incidence_exact = zeros(0, 1);
    T.surface_incidence_paraxial = zeros(0, 1);
    T.surface_normal_argument = zeros(0, 1);
    T.surface_normal_argument_clamped = zeros(0, 1);
    T.surface_sasin_clamped_flag = false(0, 1);
    T.surface_snell_argument = zeros(0, 1);
    T.surface_snell_argument_clamped = zeros(0, 1);
    T.snell_clamped_flag = false(0, 1);
    T.u_out_exact_vertex = zeros(0, 1);
    T.delta_u_vertex_scalar = zeros(0, 1);
    T.invalid_surface_normal_flag = false(0, 1);
    T.surface_intersection_s = zeros(0, 1);
    T.surface_intersection_y = zeros(0, 1);
    T.surface_intersection_exists = false(0, 1);
    T.surface_intersection_ambiguous_flag = false(0, 1);
    T.surface_intersection_root1 = zeros(0, 1);
    T.surface_intersection_root2 = zeros(0, 1);
    T.surface_intersection_residual1 = zeros(0, 1);
    T.surface_intersection_residual2 = zeros(0, 1);
    T.surface_sag_at_y0 = zeros(0, 1);
    T.surface_hit_minus_vertex_y = zeros(0, 1);
    T.surface_hit_minus_sag = zeros(0, 1);
    T.surface_alpha_hit = zeros(0, 1);
    T.surface_incidence_hit = zeros(0, 1);
    T.surface_snell_argument_hit = zeros(0, 1);
    T.surface_snell_argument_hit_clamped = zeros(0, 1);
    T.snell_hit_clamped_flag = false(0, 1);
    T.u_out_exact_hit = zeros(0, 1);
    T.delta_u_exact_hit_vs_paraxial = zeros(0, 1);
    T.delta_u_hit_vs_vertex = zeros(0, 1);
    T.no_intersection_flag = false(0, 1);
    T.invalid_hit_normal_flag = false(0, 1);
    T.tir_hit_flag = false(0, 1);
    T.warning_level = strings(0, 1);
    T.note = strings(0, 1);
end


function fieldId = field_index_local(bundleSetRow, fallback)
    fieldId = fallback;
    if isfield(bundleSetRow, 'field_index') && ...
            isfinite(bundleSetRow.field_index)
        fieldId = bundleSetRow.field_index;
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
