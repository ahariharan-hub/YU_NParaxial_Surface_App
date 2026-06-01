function count = nparaxial_count_row_union_flags_yu(T, flagNames)
%NPARAXIAL_COUNT_ROW_UNION_FLAGS_YU Count rows with any named flag true.

    if ~istable(T)
        error('T must be a table.');
    end

    flagNames = string(flagNames(:));
    rowFlags = false(height(T), 1);
    tableNames = string(T.Properties.VariableNames);

    for k = 1:numel(flagNames)
        if ~ismember(flagNames(k), tableNames)
            continue
        end
        values = T.(flagNames(k));
        if isnumeric(values) || islogical(values)
            values = logical(values(:));
        else
            values = lower(string(values(:)));
            values = ismember(values, ["true"; "1"; "yes"; "on"]);
        end
        if numel(values) ~= height(T)
            error('Flag column "%s" height does not match table height.', ...
                flagNames(k));
        end
        rowFlags = rowFlags | values;
    end

    count = sum(rowFlags);
end
