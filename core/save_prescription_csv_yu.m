function save_prescription_csv_yu(prescription, filename)
%SAVE_PRESCRIPTION_CSV_YU Save a normalized prescription table to CSV.

    filename = filename_local(filename);
    T = prescription_to_table_yu(prescription);
    writetable(T, filename);
end


function filename = filename_local(filename)
    if ~(ischar(filename) || isstring(filename)) || ~isscalar(string(filename))
        error('filename must be a text scalar.');
    end
    filename = char(filename);
end
