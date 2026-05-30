function prescription = nparaxial_validate_prescription_yu(prescription)
%NPARAXIAL_VALIDATE_PRESCRIPTION_YU Normalize and validate prescription table.
%
% Required columns:
%   element_id, type, z, aperture_radius, focal_length, radius_R,
%   n_before, n_after, enabled
%
% Optional column:
%   event_order. If omitted, table row order is used.
%
% Element types:
%   thinlens, surface, stop, dummy

    baseRequired = [
        "element_id"
        "type"
        "z"
        "aperture_radius"
        "focal_length"
        "radius_R"
        "n_before"
        "n_after"
        "enabled"
    ];

    outputColumns = [
        "element_id"
        "event_order"
        "type"
        "z"
        "aperture_radius"
        "focal_length"
        "radius_R"
        "n_before"
        "n_after"
        "enabled"
    ];

    if iscell(prescription)
        if size(prescription, 2) == numel(baseRequired)
            prescription = cell2table(prescription, 'VariableNames', cellstr(baseRequired));
        elseif size(prescription, 2) == numel(outputColumns)
            prescription = cell2table(prescription, 'VariableNames', cellstr(outputColumns));
        else
            error('Prescription cell data must have %d or %d columns.', ...
                numel(baseRequired), numel(outputColumns));
        end
    end

    if ~istable(prescription)
        error('Prescription must be a MATLAB table.');
    end

    names = string(prescription.Properties.VariableNames);
    for k = 1:numel(baseRequired)
        if ~ismember(baseRequired(k), names)
            error('Prescription is missing required column "%s".', baseRequired(k));
        end
    end

    if ~ismember("event_order", names)
        prescription.event_order = (1:height(prescription)).';
    end

    prescription = prescription(:, cellstr(outputColumns));

    prescription.element_id = string(prescription.element_id(:));
    prescription.event_order = to_double_column_local( ...
        prescription.event_order, "event_order");
    prescription.type = lower(strtrim(string(prescription.type(:))));
    prescription.z = to_double_column_local(prescription.z, "z");
    prescription.aperture_radius = to_double_column_local( ...
        prescription.aperture_radius, "aperture_radius");
    prescription.focal_length = to_double_column_local( ...
        prescription.focal_length, "focal_length");
    prescription.radius_R = to_double_column_local(prescription.radius_R, "radius_R");
    prescription.n_before = to_double_column_local(prescription.n_before, "n_before");
    prescription.n_after = to_double_column_local(prescription.n_after, "n_after");
    prescription.enabled = to_logical_column_local(prescription.enabled);

    if isempty(prescription)
        error('Prescription must contain at least one row.');
    end

    allowedTypes = ["thinlens", "surface", "stop", "dummy"];
    badType = ~ismember(prescription.type, allowedTypes);
    if any(badType)
        error('Unsupported element type "%s".', prescription.type(find(badType, 1)));
    end

    if any(strlength(prescription.element_id) == 0)
        error('element_id values must be nonempty.');
    end

    active = prescription.enabled;
    if ~any(active)
        error('At least one prescription row must be enabled.');
    end

    if any(~isfinite(prescription.event_order(active)))
        error('Enabled event_order values must be finite.');
    end

    if any(~isfinite(prescription.z(active)))
        error('Enabled element z values must be finite.');
    end

    a = prescription.aperture_radius(active);
    invalidAperture = isnan(a) | a <= 0 | (~isfinite(a) & ~isinf(a));
    if any(invalidAperture)
        error('Enabled aperture_radius values must be positive or Inf.');
    end

    nBefore = prescription.n_before(active);
    nAfter = prescription.n_after(active);
    if any(~isfinite(nBefore)) || any(nBefore <= 0) || ...
            any(~isfinite(nAfter)) || any(nAfter <= 0)
        error('Enabled n_before and n_after values must be positive and finite.');
    end

    for row = find(active).'
        elementType = prescription.type(row);

        switch elementType
            case "thinlens"
                f = prescription.focal_length(row);
                if ~isfinite(f) || f == 0
                    error('Thin lens "%s" needs finite nonzero focal_length.', ...
                        prescription.element_id(row));
                end
                validate_no_medium_change_local(prescription, row);

            case "surface"
                R = prescription.radius_R(row);
                if isnan(R) || R == 0
                    error('Surface "%s" needs radius_R nonzero or Inf.', ...
                        prescription.element_id(row));
                end

            case {"stop", "dummy"}
                validate_no_medium_change_local(prescription, row);
        end
    end

    validate_medium_continuity_local(prescription, active);
end


function values = to_double_column_local(raw, columnName)
    if iscell(raw)
        values = NaN(numel(raw), 1);
        for k = 1:numel(raw)
            values(k) = scalar_to_double_local(raw{k}, columnName);
        end
        return
    end

    if isstring(raw) || ischar(raw)
        raw = string(raw);
        values = NaN(numel(raw), 1);
        for k = 1:numel(raw)
            values(k) = str2double(raw(k));
        end
    else
        values = double(raw);
    end

    values = values(:);
    if any(isnan(values))
        error('Column "%s" contains NaN or nonnumeric values.', columnName);
    end
end


function value = scalar_to_double_local(raw, columnName)
    if isnumeric(raw) || islogical(raw)
        if ~isscalar(raw)
            error('Column "%s" contains a nonscalar value.', columnName);
        end
        value = double(raw);
    elseif isstring(raw) || ischar(raw)
        value = str2double(string(raw));
    else
        error('Column "%s" contains a value that cannot be converted.', columnName);
    end

    if isnan(value)
        error('Column "%s" contains NaN or nonnumeric values.', columnName);
    end
end


function values = to_logical_column_local(raw)
    if iscell(raw)
        values = false(numel(raw), 1);
        for k = 1:numel(raw)
            values(k) = scalar_to_logical_local(raw{k}, k);
        end
        return
    end

    if isstring(raw) || ischar(raw)
        raw = string(raw);
        values = false(numel(raw), 1);
        for k = 1:numel(raw)
            values(k) = scalar_to_logical_local(raw(k), k);
        end
    elseif islogical(raw)
        values = raw;
    elseif isnumeric(raw)
        raw = double(raw);
        bad = isnan(raw) | ~(raw == 0 | raw == 1);
        if any(bad(:))
            error(['Column "enabled" must contain logical true/false, numeric 0/1, ', ...
                'or strings true/false, yes/no, on/off, 1/0.']);
        end
        values = logical(raw);
    else
        error(['Column "enabled" must contain logical true/false, numeric 0/1, ', ...
            'or strings true/false, yes/no, on/off, 1/0.']);
    end

    values = values(:);
end


function value = scalar_to_logical_local(raw, rowIndex)
    if islogical(raw)
        if ~isscalar(raw)
            error('Column "enabled" row %d must be scalar.', rowIndex);
        end
        value = raw;
    elseif isnumeric(raw)
        if ~isscalar(raw) || isnan(raw) || ~(raw == 0 || raw == 1)
            error(['Column "enabled" row %d must be logical true/false, numeric 0/1, ', ...
                'or strings true/false, yes/no, on/off, 1/0.'], rowIndex);
        end
        value = logical(raw);
    elseif isstring(raw) || ischar(raw)
        token = lower(strtrim(string(raw)));
        if ismember(token, ["true", "1", "yes", "on"])
            value = true;
        elseif ismember(token, ["false", "0", "no", "off"])
            value = false;
        else
            error(['Column "enabled" row %d has invalid value "%s". Valid choices are ', ...
                'true/false, yes/no, on/off, 1/0, logical true/false, or numeric 0/1.'], ...
                rowIndex, token);
        end
    else
        error(['Column "enabled" row %d must be logical true/false, numeric 0/1, ', ...
            'or strings true/false, yes/no, on/off, 1/0.'], rowIndex);
    end
end


function validate_no_medium_change_local(prescription, row)
    tol = 1e-12;
    nBefore = prescription.n_before(row);
    nAfter = prescription.n_after(row);

    if abs(nAfter - nBefore) > tol
        error(['Element "%s" has type "%s", which must not change medium. ', ...
            'Use n_before == n_after for thinlens, stop, and dummy elements.'], ...
            prescription.element_id(row), prescription.type(row));
    end
end


function validate_medium_continuity_local(prescription, active)
    elements = prescription(active, :);
    if isempty(elements)
        return
    end

    rowOrder = (1:height(prescription)).';
    activeRows = rowOrder(active);
    [~, idx] = sortrows([elements.z, elements.event_order, activeRows]);
    elements = elements(idx, :);

    tol = 1e-12;
    currentMedium = elements.n_before(1);

    for k = 1:height(elements)
        nBefore = elements.n_before(k);
        nAfter = elements.n_after(k);

        if abs(nBefore - currentMedium) > tol
            error(['Medium continuity violation at element "%s": n_before = %.12g, ', ...
                'but the current medium before this element is %.12g.'], ...
                elements.element_id(k), nBefore, currentMedium);
        end

        switch elements.type(k)
            case "surface"
                currentMedium = nAfter;

            case {"thinlens", "stop", "dummy"}
                if abs(nAfter - currentMedium) > tol
                    error(['Medium continuity violation at element "%s": type "%s" ', ...
                        'must keep n_before == n_after == current medium %.12g.'], ...
                        elements.element_id(k), elements.type(k), currentMedium);
                end
        end
    end
end
