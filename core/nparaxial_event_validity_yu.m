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
                    diagnosticType = "spherical_surface_deferred";
                    note = "Spherical-surface scalar validity is deferred to Milestone 2.3.4.";
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
