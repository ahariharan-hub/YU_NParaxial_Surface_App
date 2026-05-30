function prescription = load_prescription_mat_yu(filename)
%LOAD_PRESCRIPTION_MAT_YU Load and validate a prescription table from MAT.

    filename = filename_local(filename);
    S = load(filename);

    if isfield(S, 'prescription')
        raw = S.prescription;
    else
        fieldNames = string(fieldnames(S));
        tableMask = false(numel(fieldNames), 1);
        for k = 1:numel(fieldNames)
            tableMask(k) = istable(S.(char(fieldNames(k))));
        end

        tableFields = fieldNames(tableMask);
        if numel(tableFields) ~= 1
            error('MAT file must contain a prescription variable or exactly one table.');
        end
        raw = S.(char(tableFields(1)));
    end

    prescription = table_to_prescription_yu(raw);
end


function filename = filename_local(filename)
    if ~(ischar(filename) || isstring(filename)) || ~isscalar(string(filename))
        error('filename must be a text scalar.');
    end
    filename = char(filename);
end
