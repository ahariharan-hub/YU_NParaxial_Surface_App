function vig = nparaxial_vignetting_intervals_yu( ...
    prescription, z_obj, y_obj, z_end, tol)
%NPARAXIAL_VIGNETTING_INTERVALS_YU First-order launch-slope intervals.
%
% Each finite aperture constrains the object-side launch slope u0 by
% |A_i*y_obj + B_i*u0| <= a_i. The cumulative unvignetted cone is the
% intersection of all such intervals in event-sequence order.

    if nargin < 3 || isempty(y_obj)
        y_obj = 0;
    end
    if nargin < 4 || isempty(z_end)
        z_end = Inf;
    end
    if nargin < 5 || isempty(tol)
        tol = 1e-12;
    end
    if ~isscalar(z_obj) || ~isfinite(z_obj) || ...
            ~isscalar(y_obj) || ~isfinite(y_obj) || ...
            ~isscalar(z_end) || isnan(z_end)
        error('z_obj and y_obj must be finite scalars; z_end must be scalar or Inf.');
    end
    if isfinite(z_end) && z_end < z_obj
        error('z_end must be greater than or equal to z_obj.');
    end

    prescription = nparaxial_validate_prescription_yu(prescription);
    events = nparaxial_event_sequence_yu(prescription, z_obj, z_end);
    [candidateTable, cumulativeTable, finalData] = ...
        interval_tables_local(events, z_obj, y_obj, tol);
    [~, ~, axialData] = interval_tables_local(events, z_obj, 0, tol);

    partialRelativeToAxial = partial_relative_to_axial_local( ...
        finalData, axialData, tol);

    vig = struct();
    vig.z_obj = z_obj;
    vig.y_obj = y_obj;
    vig.z_end = z_end;
    vig.candidate_table = candidateTable;
    vig.cumulative_table = cumulativeTable;
    vig.has_finite_apertures = ~isempty(candidateTable);
    vig.fully_vignetted = finalData.fully_vignetted;
    vig.u_low = finalData.u_low;
    vig.u_high = finalData.u_high;
    vig.u_center = finalData.u_center;
    vig.u_semi_width = finalData.u_semi_width;
    vig.is_symmetric = finalData.is_symmetric;
    vig.lower_bound_event_index = finalData.lower_bound_event_index;
    vig.lower_bound_element_id = finalData.lower_bound_element_id;
    vig.upper_bound_event_index = finalData.upper_bound_event_index;
    vig.upper_bound_element_id = finalData.upper_bound_element_id;
    vig.axial_u_low = axialData.u_low;
    vig.axial_u_high = axialData.u_high;
    vig.axial_u_center = axialData.u_center;
    vig.axial_u_semi_width = axialData.u_semi_width;
    vig.partially_vignetted_relative_to_axial = partialRelativeToAxial;
    vig.note = status_text_local(vig);
end


function [candidateTable, cumulativeTable, finalData] = interval_tables_local( ...
    events, z_obj, y_obj, tol)

    finiteMask = isfinite(events.aperture_radius) & ...
        events.aperture_radius > 0 & events.z >= z_obj - tol;
    candidates = events(finiteMask, :);

    candidateTable = empty_candidate_table_local();
    cumulativeTable = empty_cumulative_table_local();

    uLowTotal = -Inf;
    uHighTotal = Inf;
    lowerId = "";
    upperId = "";
    lowerEventIndex = NaN;
    upperEventIndex = NaN;
    fullyVignetted = false;

    for k = 1:height(candidates)
        event = candidates(k, :);
        preEvents = events(events.event_index < event.event_index, :);
        M = nparaxial_partial_system_matrix_yu(preEvents, z_obj, event.z(1));
        A = M(1, 1);
        B = M(1, 2);
        a = event.aperture_radius(1);
        yAtZeroSlope = A*y_obj;

        [uLow, uHigh, intervalEmpty, passesAllSlopes] = ...
            aperture_interval_local(A, B, y_obj, a, tol);
        intervalWidth = uHigh - uLow;
        if intervalEmpty
            intervalWidth = NaN;
        end

        candidateTable(end+1, :) = { ...
            event.event_index(1), event.original_row(1), event.element_id(1), ...
            event.type(1), event.z(1), event.aperture_radius(1), ...
            A, B, yAtZeroSlope, uLow, uHigh, intervalWidth, ...
            intervalEmpty, passesAllSlopes}; %#ok<AGROW>

        if intervalEmpty
            uLow = Inf;
            uHigh = -Inf;
        end

        if uLow > uLowTotal + tol || ...
                (isinf(uLow) && uLow > uLowTotal)
            uLowTotal = uLow;
            lowerId = event.element_id(1);
            lowerEventIndex = event.event_index(1);
        end
        if uHigh < uHighTotal - tol || ...
                (isinf(uHigh) && uHigh < uHighTotal)
            uHighTotal = uHigh;
            upperId = event.element_id(1);
            upperEventIndex = event.event_index(1);
        end

        fullyVignetted = fullyVignetted || (uLowTotal > uHighTotal + tol);
        cumulativeTable(end+1, :) = { ...
            event.event_index(1), event.original_row(1), event.element_id(1), ...
            event.type(1), event.z(1), event.aperture_radius(1), ...
            candidateTable.u_low(end), candidateTable.u_high(end), ...
            uLowTotal, uHighTotal, lowerId, upperId, ...
            fullyVignetted}; %#ok<AGROW>
    end

    finalData = final_data_local( ...
        uLowTotal, uHighTotal, lowerId, upperId, ...
        lowerEventIndex, upperEventIndex, fullyVignetted, tol);
end


function [uLow, uHigh, intervalEmpty, passesAllSlopes] = ...
    aperture_interval_local(A, B, y_obj, aperture, tol)

    passesAllSlopes = false;
    if abs(B) <= tol
        if abs(A*y_obj) <= aperture + tol
            uLow = -Inf;
            uHigh = Inf;
            intervalEmpty = false;
            passesAllSlopes = true;
        else
            uLow = NaN;
            uHigh = NaN;
            intervalEmpty = true;
        end
        return
    end

    endpoint1 = (-aperture - A*y_obj)/B;
    endpoint2 = (aperture - A*y_obj)/B;
    uLow = min(endpoint1, endpoint2);
    uHigh = max(endpoint1, endpoint2);
    intervalEmpty = false;
end


function finalData = final_data_local( ...
    uLow, uHigh, lowerId, upperId, lowerEventIndex, upperEventIndex, ...
    fullyVignetted, tol)

    if fullyVignetted || uLow > uHigh + tol
        fullyVignetted = true;
        uCenter = NaN;
        uSemiWidth = NaN;
        isSymmetric = false;
    elseif isinf(uLow) || isinf(uHigh)
        uCenter = NaN;
        uSemiWidth = Inf;
        isSymmetric = isinf(uLow) && uLow < 0 && isinf(uHigh) && uHigh > 0;
    else
        uCenter = 0.5*(uLow + uHigh);
        uSemiWidth = 0.5*(uHigh - uLow);
        isSymmetric = abs(uLow + uHigh) <= tol*max(1, abs(uHigh - uLow));
    end

    finalData = struct();
    finalData.u_low = uLow;
    finalData.u_high = uHigh;
    finalData.u_center = uCenter;
    finalData.u_semi_width = uSemiWidth;
    finalData.is_symmetric = isSymmetric;
    finalData.fully_vignetted = fullyVignetted;
    finalData.lower_bound_element_id = string(lowerId);
    finalData.upper_bound_element_id = string(upperId);
    finalData.lower_bound_event_index = lowerEventIndex;
    finalData.upper_bound_event_index = upperEventIndex;
end


function isPartial = partial_relative_to_axial_local(fieldData, axialData, tol)
    isPartial = false;
    if fieldData.fully_vignetted
        isPartial = ~axialData.fully_vignetted;
        return
    end
    if axialData.fully_vignetted
        return
    end

    fieldWidth = fieldData.u_high - fieldData.u_low;
    axialWidth = axialData.u_high - axialData.u_low;
    if isinf(axialWidth) && isfinite(fieldWidth)
        isPartial = true;
    elseif isfinite(axialWidth) && isfinite(fieldWidth)
        scale = max(1, abs(axialWidth));
        isPartial = fieldWidth < axialWidth - tol*scale;
    end
end


function note = status_text_local(vig)
    if ~vig.has_finite_apertures
        note = "No finite aperture candidates were found; launch-slope interval is unbounded.";
    elseif vig.fully_vignetted
        note = "The selected field is fully vignetted by the cumulative aperture intervals.";
    else
        note = "First-order meridional vignetting interval computed from cumulative aperture intersections.";
    end
end


function T = empty_candidate_table_local()
    T = table( ...
        zeros(0, 1), zeros(0, 1), strings(0, 1), strings(0, 1), ...
        zeros(0, 1), zeros(0, 1), zeros(0, 1), zeros(0, 1), ...
        zeros(0, 1), zeros(0, 1), zeros(0, 1), zeros(0, 1), ...
        false(0, 1), false(0, 1), ...
        'VariableNames', { ...
        'event_index', 'original_row', 'element_id', 'type', ...
        'z', 'aperture_radius', 'A_to_aperture', 'B_to_aperture', ...
        'y_at_u0_zero', 'u_low', 'u_high', 'interval_width', ...
        'interval_empty', 'passes_all_slopes'});
end


function T = empty_cumulative_table_local()
    T = table( ...
        zeros(0, 1), zeros(0, 1), strings(0, 1), strings(0, 1), ...
        zeros(0, 1), zeros(0, 1), zeros(0, 1), zeros(0, 1), ...
        zeros(0, 1), zeros(0, 1), strings(0, 1), strings(0, 1), ...
        false(0, 1), ...
        'VariableNames', { ...
        'event_index', 'original_row', 'element_id', 'type', ...
        'z', 'aperture_radius', 'candidate_u_low', 'candidate_u_high', ...
        'u_low_total', 'u_high_total', 'lower_bound_element_id', ...
        'upper_bound_element_id', 'fully_vignetted'});
end
