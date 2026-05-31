function lines = nparaxial_table_to_text_yu(T)
%NPARAXIAL_TABLE_TO_TEXT_YU Serialize a table without MATLAB display wrapping.

    if ~istable(T)
        error('Input must be a MATLAB table.');
    end

    names = string(T.Properties.VariableNames);
    if isempty(T)
        lines = [
            "Variables: " + strjoin(names, ", ")
            "(empty table)"
            ];
        return
    end

    lines = "Variables: " + strjoin(names, ", ");
    for r = 1:height(T)
        parts = strings(1, numel(names));
        for c = 1:numel(names)
            columnData = T.(char(names(c)));
            parts(c) = names(c) + "=" + value_to_text_local(columnData, r);
        end
        lines(end+1, 1) = sprintf('row %d: %s', ...
            r, strjoin(parts, '; ')); %#ok<AGROW>
    end
end


function text = value_to_text_local(columnData, row)
    if iscell(columnData)
        raw = columnData{row};
    else
        raw = columnData(row, :);
    end

    if isstring(raw) || ischar(raw)
        text = strjoin(string(raw(:).'), ",");
    elseif isnumeric(raw)
        text = numeric_to_text_local(raw);
    elseif islogical(raw)
        text = logical_to_text_local(raw);
    elseif iscategorical(raw)
        text = strjoin(string(raw(:).'), ",");
    elseif isdatetime(raw) || isduration(raw)
        text = strjoin(string(raw(:).'), ",");
    else
        text = "<unsupported>";
    end
end


function text = numeric_to_text_local(raw)
    if isempty(raw)
        text = "";
    elseif isscalar(raw)
        text = sprintf('%.12g', raw);
    else
        text = string(mat2str(raw, 12));
    end
end


function text = logical_to_text_local(raw)
    if isempty(raw)
        text = "";
    elseif isscalar(raw)
        text = string(raw);
    else
        text = string(mat2str(raw));
    end
end
