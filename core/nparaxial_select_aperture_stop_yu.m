function stopDiag = nparaxial_select_aperture_stop_yu( ...
    prescription, z_obj, y_obj, tol)
%NPARAXIAL_SELECT_APERTURE_STOP_YU Select aperture stop by launch interval.

    if nargin < 3 || isempty(y_obj)
        y_obj = 0;
    end
    if nargin < 4 || isempty(tol)
        tol = 1e-12;
    end
    if ~isscalar(z_obj) || ~isfinite(z_obj) || ...
            ~isscalar(y_obj) || ~isfinite(y_obj)
        error('z_obj and y_obj must be finite scalars.');
    end

    events = nparaxial_event_sequence_yu(prescription);
    offAxisWarning = "";
    if abs(y_obj) > tol
        offAxisWarning = ['Stop selection is axial-first-order only; ', ...
            'off-axis fields require vignetting interval diagnostics not ', ...
            'implemented in this milestone.'];
    end

    finiteMask = isfinite(events.aperture_radius) & ...
        events.aperture_radius > 0 & events.z >= z_obj - tol;
    candidates = events(finiteMask, :);

    T = empty_candidate_table_local();
    for k = 1:height(candidates)
        event = candidates(k, :);
        preEvents = events(events.event_index < event.event_index, :);
        M = nparaxial_partial_system_matrix_yu(preEvents, z_obj, event.z(1));
        A = M(1, 1);
        B = M(1, 2);
        a = event.aperture_radius(1);

        if abs(B) <= tol
            if abs(A*y_obj) <= a + tol
                uMin = -Inf;
                uMax = Inf;
                width = Inf;
                valid = true;
            else
                uMin = NaN;
                uMax = NaN;
                width = NaN;
                valid = false;
            end
        else
            center = -A*y_obj / B;
            halfWidth = a / abs(B);
            uMin = center - halfWidth;
            uMax = center + halfWidth;
            width = uMax - uMin;
            valid = true;
        end

        T(end+1, :) = { ...
            event.event_index(1), event.original_row(1), event.element_id(1), ...
            event.type(1), event.z(1), event.aperture_radius(1), ...
            A, B, uMin, uMax, width, valid}; %#ok<AGROW>
    end

    finiteValid = T.valid & isfinite(T.interval_width);
    if any(finiteValid)
        idxList = find(finiteValid);
        [~, localIdx] = min(T.interval_width(finiteValid));
        selectedRow = idxList(localIdx);
    else
        selectedRow = [];
    end

    stopDiag = struct();
    stopDiag.z_obj = z_obj;
    stopDiag.y_obj = y_obj;
    stopDiag.candidate_table = T;
    stopDiag.off_axis_warning = string(offAxisWarning);
    stopDiag.has_stop = ~isempty(selectedRow);
    stopDiag.selected_event_index = NaN;
    stopDiag.selected_original_row = NaN;
    stopDiag.selected_element_id = "";
    stopDiag.selected_z = NaN;
    stopDiag.selected_aperture_radius = NaN;
    stopDiag.selected_event = table();
    stopDiag.note = "No finite aperture candidate with finite launch interval was found.";

    if stopDiag.has_stop
        stopDiag.selected_event_index = T.event_index(selectedRow);
        stopDiag.selected_original_row = T.original_row(selectedRow);
        stopDiag.selected_element_id = T.element_id(selectedRow);
        stopDiag.selected_z = T.z(selectedRow);
        stopDiag.selected_aperture_radius = T.aperture_radius(selectedRow);
        stopDiag.selected_event = events( ...
            events.event_index == stopDiag.selected_event_index, :);
        stopDiag.note = "Finite aperture stop selected by tightest axial launch-slope interval.";
        if strlength(stopDiag.off_axis_warning) > 0
            stopDiag.note = stopDiag.note + " " + stopDiag.off_axis_warning;
        end
    end
end


function T = empty_candidate_table_local()
    T = table( ...
        zeros(0, 1), zeros(0, 1), strings(0, 1), strings(0, 1), ...
        zeros(0, 1), zeros(0, 1), zeros(0, 1), zeros(0, 1), ...
        zeros(0, 1), zeros(0, 1), zeros(0, 1), false(0, 1), ...
        'VariableNames', { ...
        'event_index', 'original_row', 'element_id', 'type', ...
        'z', 'aperture_radius', 'A_to_aperture', 'B_to_aperture', ...
        'u_min', 'u_max', 'interval_width', 'valid'});
end
