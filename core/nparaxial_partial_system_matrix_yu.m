function M = nparaxial_partial_system_matrix_yu(events, z_in, z_out)
%NPARAXIAL_PARTIAL_SYSTEM_MATRIX_YU Matrix through an explicit event subset.
%
% The caller supplies the exact events to include. This avoids ambiguous
% z-only filtering when multiple elements share one plane.

    if ~isscalar(z_in) || ~isscalar(z_out) || ...
            ~isfinite(z_in) || ~isfinite(z_out)
        error('z_in and z_out must be finite scalar values.');
    end
    if z_out < z_in
        error('Forward propagation requires z_out >= z_in.');
    end

    if ~isempty(events)
        events = nparaxial_event_sort_local(events);
    end

    M = eye(2);
    zCurr = z_in;

    for k = 1:height(events)
        zElement = events.z(k);
        d = zElement - zCurr;
        if d < -1e-12
            error('Partial event sequence must be ordered forward in z.');
        end

        T = [1, d; 0, 1];
        M = T * M;

        E = nparaxial_element_matrix_yu(events(k, :));
        M = E * M;

        zCurr = zElement;
    end

    T = [1, z_out - zCurr; 0, 1];
    M = T * M;
end


function events = nparaxial_event_sort_local(events)
    if ~istable(events)
        error('events must be a MATLAB table.');
    end
    if ismember('original_row', events.Properties.VariableNames)
        originalRow = events.original_row;
    else
        originalRow = (1:height(events)).';
    end

    events = nparaxial_validate_prescription_yu(events);
    enabled = events.enabled;
    events = events(enabled, :);
    originalRow = originalRow(enabled);
    if isempty(events)
        return
    end

    [~, idx] = sortrows([events.z, events.event_order, originalRow]);
    events = events(idx, :);
end
