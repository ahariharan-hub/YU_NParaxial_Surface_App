function nparaxial_export_table_csv_yu(T, filename)
%NPARAXIAL_EXPORT_TABLE_CSV_YU Generic checked table-to-CSV export.

    if ~istable(T)
        error('Export data must be a MATLAB table.');
    end
    if isempty(T)
        error('Export table is empty or unavailable.');
    end

    filename = filename_local(filename);
    writetable(T, filename);
end


function filename = filename_local(filename)
    if ~(ischar(filename) || isstring(filename)) || ~isscalar(string(filename))
        error('filename must be a text scalar.');
    end
    filename = char(filename);
end
