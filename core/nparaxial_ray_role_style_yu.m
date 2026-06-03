function [color, lineStyle, displayName, marker, lineWidth, role] = ...
    nparaxial_ray_role_style_yu(rayInfo, clipped)
%NPARAXIAL_RAY_ROLE_STYLE_YU Return plotting style for ray role colors.
%
% Ray role colors:
%   UMR upper marginal ray: blue
%   CR  chief ray: red
%   LMR lower marginal ray: green

    if nargin < 2 || isempty(clipped)
        clipped = false;
    end

    if istable(rayInfo) && (height(rayInfo) ~= 1 || numel(clipped) ~= 1) && ...
            nargout <= 1
        color = style_table_local(rayInfo, clipped);
        return
    end

    if istable(rayInfo) && height(rayInfo) > 1
        error(['For multiple rays, request one output from ', ...
            'nparaxial_ray_role_style_yu.']);
    end

    clipped = logical(clipped(1));
    role = infer_single_role_local(rayInfo);
    [color, lineStyle, displayName, marker, lineWidth] = ...
        style_from_role_local(role, clipped);

    if nargout <= 1
        color = struct( ...
            'role', role, ...
            'color', color, ...
            'line_style', string(lineStyle), ...
            'display_name', string(displayName), ...
            'marker', string(marker), ...
            'line_width', lineWidth);
    end
end


function styles = style_table_local(rayTable, clipped)
    n = height(rayTable);
    clipped = normalize_clipped_local(clipped, n);
    roles = infer_roles_from_table_local(rayTable);

    color = NaN(n, 3);
    line_style = strings(n, 1);
    display_name = strings(n, 1);
    marker = strings(n, 1);
    line_width = NaN(n, 1);

    for k = 1:n
        [color(k, :), line_style(k), display_name(k), marker(k), ...
            line_width(k)] = style_from_role_local(roles(k), clipped(k));
    end

    styles = table(roles, color, line_style, display_name, marker, ...
        line_width, 'VariableNames', {'role', 'color', 'line_style', ...
        'display_name', 'marker', 'line_width'});
end


function clipped = normalize_clipped_local(clipped, n)
    if isempty(clipped)
        clipped = false(n, 1);
    elseif isscalar(clipped)
        clipped = repmat(logical(clipped), n, 1);
    else
        clipped = logical(clipped(:));
        if numel(clipped) ~= n
            error('clipped must be scalar or match the number of rays.');
        end
    end
end


function role = infer_single_role_local(rayInfo)
    if istable(rayInfo)
        role = infer_explicit_role_local(rayInfo);
    else
        role = normalize_role_text_local(string(rayInfo));
    end

    if strlength(role) == 0
        role = "intermediate";
    end
end


function roles = infer_roles_from_table_local(rayTable)
    n = height(rayTable);
    roles = strings(n, 1);
    for k = 1:n
        roles(k) = infer_explicit_role_local(rayTable(k, :));
    end

    [coord, target] = coordinate_for_role_ordering_local(rayTable);
    if ~isempty(coord)
        roles = fill_roles_from_coordinate_local(roles, coord, target);
    end

    roles(strlength(roles) == 0) = "intermediate";
end


function roles = fill_roles_from_coordinate_local(roles, coord, target)
    finiteIdx = find(isfinite(coord));
    if isempty(finiteIdx)
        return
    end

    finiteCoord = coord(finiteIdx);
    tol = max(1e-12, 1e-12*max(abs(finiteCoord)));

    [~, minPos] = min(finiteCoord);
    [~, maxPos] = max(finiteCoord);
    [~, chiefPos] = min(abs(finiteCoord - target));

    lmrIdx = finiteIdx(minPos);
    umrIdx = finiteIdx(maxPos);
    crIdx = finiteIdx(chiefPos);

    if max(finiteCoord) - min(finiteCoord) > tol
        roles = assign_role_if_missing_local(roles, lmrIdx, "LMR");
        roles = assign_role_if_missing_local(roles, umrIdx, "UMR");
    end
    roles = assign_role_if_missing_local(roles, crIdx, "CR");
end


function roles = assign_role_if_missing_local(roles, idx, roleName)
    if any(roles == roleName)
        return
    end
    if strlength(roles(idx)) == 0 || roles(idx) == "intermediate"
        roles(idx) = roleName;
    end
end


function [coord, target] = coordinate_for_role_ordering_local(rayTable)
    coord = [];
    target = 0;

    if ~istable(rayTable) || height(rayTable) == 0
        return
    end

    names = string(rayTable.Properties.VariableNames);
    stopColumns = ["h_stop_target", "pupil_coordinate", ...
        "stop_coordinate", "target_stop_y", "y_target"];
    for k = 1:numel(stopColumns)
        if ismember(stopColumns(k), names)
            coord = double(rayTable.(stopColumns(k)));
            target = 0;
            return
        end
    end

    if ismember("u_fraction", names)
        coord = double(rayTable.u_fraction);
        target = 0.5;
        return
    end

    if ismember("fan_coordinate", names)
        coord = double(rayTable.fan_coordinate);
        target = 0;
        return
    end

    if ismember("u0", names)
        coord = double(rayTable.u0);
        finiteCoord = coord(isfinite(coord));
        if ~isempty(finiteCoord)
            target = 0.5*(min(finiteCoord) + max(finiteCoord));
        end
    end
end


function role = infer_explicit_role_local(rayRow)
    role = "";
    if ~istable(rayRow) || height(rayRow) == 0
        return
    end

    names = string(rayRow.Properties.VariableNames);
    if flag_true_local(rayRow, names, "is_upper_marginal")
        role = "UMR";
        return
    elseif flag_true_local(rayRow, names, "is_chief")
        role = "CR";
        return
    elseif flag_true_local(rayRow, names, "is_lower_marginal")
        role = "LMR";
        return
    end

    roleColumns = ["ray_role", "role"];
    for k = 1:numel(roleColumns)
        if ismember(roleColumns(k), names)
            role = normalize_role_text_local(string(rayRow.(roleColumns(k))));
            if strlength(role) > 0
                return
            end
        end
    end

    nameColumns = ["ray_name", "name", "display_name"];
    for k = 1:numel(nameColumns)
        if ismember(nameColumns(k), names)
            role = normalize_role_text_local(string(rayRow.(nameColumns(k))));
            if strlength(role) > 0
                return
            end
        end
    end
end


function tf = flag_true_local(rayRow, names, flagName)
    tf = false;
    if ~ismember(flagName, names)
        return
    end
    value = rayRow.(flagName);
    if islogical(value) || isnumeric(value)
        tf = logical(value(1));
    else
        tf = any(strcmpi(string(value(1)), ["true", "1", "yes"]));
    end
end


function role = normalize_role_text_local(value)
    value = lower(strtrim(string(value(1))));
    role = "";

    if value == "umr" || contains(value, "upper_marginal") || ...
            contains(value, "upper marginal") || ...
            contains(value, "aperture_limited_upper")
        role = "UMR";
    elseif value == "cr" || contains(value, "chief") || ...
            contains(value, "aperture_limited_center")
        role = "CR";
    elseif value == "lmr" || contains(value, "lower_marginal") || ...
            contains(value, "lower marginal") || ...
            contains(value, "aperture_limited_lower")
        role = "LMR";
    elseif contains(value, "intermediate") || startsWith(value, "ray_") || ...
            startsWith(value, "pupil_")
        role = "intermediate";
    end
end


function [color, lineStyle, displayName, marker, lineWidth] = ...
    style_from_role_local(role, clipped)
    switch string(role)
        case "UMR"
            color = [0 0.4470 0.7410];
            displayName = "UMR";
            lineWidth = 1.2;
        case "CR"
            color = [0.8500 0.0000 0.0000];
            displayName = "CR";
            lineWidth = 1.4;
        case "LMR"
            color = [0.0000 0.6000 0.0000];
            displayName = "LMR";
            lineWidth = 1.2;
        otherwise
            color = [0.56 0.56 0.56];
            displayName = "Intermediate ray";
            lineWidth = 0.8;
    end

    lineStyle = "-";
    marker = "none";
    if clipped
        lineStyle = "--";
        marker = "x";
        lineWidth = lineWidth + 0.2;
    end
end
