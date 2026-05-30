function prescription = load_prescription_csv_yu(filename)
%LOAD_PRESCRIPTION_CSV_YU Load and validate a prescription table from CSV.

    filename = filename_local(filename);
    opts = detectImportOptions(filename, 'TextType', 'string');
    names = string(opts.VariableNames);
    if ismember("element_id", names)
        opts = setvartype(opts, 'element_id', 'string');
    end
    if ismember("type", names)
        opts = setvartype(opts, 'type', 'string');
    end

    T = readtable(filename, opts);
    prescription = table_to_prescription_yu(T);
end


function filename = filename_local(filename)
    if ~(ischar(filename) || isstring(filename)) || ~isscalar(string(filename))
        error('filename must be a text scalar.');
    end
    filename = char(filename);
end
