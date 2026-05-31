function events = nparaxial_event_sequence_yu(prescription, z_in, z_out)
%NPARAXIAL_EVENT_SEQUENCE_YU Enabled events sorted by z, event_order, row.

    if nargin < 2 || isempty(z_in)
        z_in = -Inf;
    end
    if nargin < 3 || isempty(z_out)
        z_out = Inf;
    end
    if ~isscalar(z_in) || ~isscalar(z_out) || isnan(z_in) || isnan(z_out)
        error('z_in and z_out must be scalar values or +/-Inf.');
    end

    prescription = nparaxial_validate_prescription_yu(prescription);
    originalRow = (1:height(prescription)).';

    zLo = min(z_in, z_out);
    zHi = max(z_in, z_out);
    tol = 1e-12;
    active = prescription.enabled & ...
        prescription.z >= zLo - tol & prescription.z <= zHi + tol;

    events = prescription(active, :);
    if isempty(events)
        events.original_row = zeros(0, 1);
        events.event_index = zeros(0, 1);
        return
    end

    activeRows = originalRow(active);
    [~, idx] = sortrows([events.z, events.event_order, activeRows]);
    events = events(idx, :);
    activeRows = activeRows(idx);

    events.original_row = activeRows;
    events.event_index = (1:height(events)).';
end
