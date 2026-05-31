function filename = nparaxial_export_summary_txt_yu(lines, filename)
%NPARAXIAL_EXPORT_SUMMARY_TXT_YU Write cell/string report lines to TXT.

    filename = filename_local(filename, '.txt');
    lines = string(lines(:));

    fid = fopen(filename, 'w');
    if fid < 0
        error('Could not open "%s" for writing.', filename);
    end
    cleanup = onCleanup(@() fclose(fid));

    for k = 1:numel(lines)
        fprintf(fid, '%s\n', lines(k));
    end
end


function filename = filename_local(filename, extension)
    if ~(ischar(filename) || isstring(filename)) || ~isscalar(string(filename))
        error('filename must be a text scalar.');
    end
    filename = char(filename);
    if length(filename) < length(extension) || ...
            ~strcmpi(filename(end-length(extension)+1:end), extension)
        filename = [filename, extension];
    end
end
