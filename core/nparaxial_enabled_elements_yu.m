function elements = nparaxial_enabled_elements_yu(prescription, z_in, z_out)
%NPARAXIAL_ENABLED_ELEMENTS_YU Return enabled elements sorted by z and row.

    if nargin < 2
        z_in = -Inf;
    end
    if nargin < 3
        z_out = Inf;
    end

    prescription = nparaxial_validate_prescription_yu(prescription);
    rowOrder = (1:height(prescription)).';
    active = prescription.enabled;

    zLo = min(z_in, z_out);
    zHi = max(z_in, z_out);
    tol = 1e-12;
    active = active & prescription.z >= zLo - tol & prescription.z <= zHi + tol;

    elements = prescription(active, :);
    if isempty(elements)
        return
    end

    activeRows = rowOrder(active);
    [~, idx] = sortrows([elements.z, elements.event_order, activeRows]);
    elements = elements(idx, :);
end
