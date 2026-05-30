function save_prescription_mat_yu(prescription, filename)
%SAVE_PRESCRIPTION_MAT_YU Save a normalized prescription table to MAT.

    filename = filename_local(filename);
    prescription = prescription_to_table_yu(prescription); %#ok<NASGU>
    save(filename, 'prescription');
end


function filename = filename_local(filename)
    if ~(ischar(filename) || isstring(filename)) || ~isscalar(string(filename))
        error('filename must be a text scalar.');
    end
    filename = char(filename);
end
