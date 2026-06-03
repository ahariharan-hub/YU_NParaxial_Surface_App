function results = demo_nparaxial_milestone247_ray_legend_export_yu()
%DEMO_NPARAXIAL_MILESTONE247_RAY_LEGEND_EXPORT_YU Legend/export checks.

    testFolder = fileparts(mfilename('fullpath'));
    rootFolder = fileparts(testFolder);
    addpath(rootFolder);
    addpath(fullfile(rootFolder, 'core'));

    numChecks = 0;

    p = make_prescription_local("STOP", "stop", 10, 2);

    rays3 = nparaxial_make_aperture_limited_rays_yu( ...
        p, 0, 0, 3, 0.04, 1e-12, 10);
    styles3 = nparaxial_ray_role_style_yu(rays3, false(height(rays3), 1));
    [~, names3, fig3] = legend_names_for_styles_local(styles3, ...
        false(height(styles3), 1), true);
    close(fig3);
    assert_exact_counts_local(names3, ["UMR"; "CR"; "LMR"]);
    numChecks = numChecks + 1;

    rays5 = nparaxial_make_aperture_limited_rays_yu( ...
        p, 0, 0, 5, 0.04, 1e-12, 10);
    styles5 = nparaxial_ray_role_style_yu(rays5, false(height(rays5), 1));
    [~, names5, fig5] = legend_names_for_styles_local(styles5, ...
        false(height(styles5), 1), true);
    close(fig5);
    assert_exact_counts_local(names5, ...
        ["UMR"; "CR"; "LMR"; "Intermediate"]);
    numChecks = numChecks + 1;

    clipped = [true; false; true; false; true];
    clippedStyles = nparaxial_ray_role_style_yu(rays5, clipped);
    [legendHandles, clippedNames, fig] = legend_names_for_styles_local( ...
        clippedStyles, clipped, true);
    cleanupFig = onCleanup(@() close(fig)); %#ok<NASGU>
    assert(count_name_local(clippedNames, "Clipped ray") == 1, ...
        'Clipped marker legend entry should appear exactly once.');
    assert(numel(clippedNames) == numel(unique(clippedNames)), ...
        'Legend entries should not contain duplicates.');
    numChecks = numChecks + 1;

    expectedOrder = ["UMR"; "CR"; "LMR"; "Intermediate"; "Clipped ray"];
    assert(isequal(clippedNames, expectedOrder), ...
        'Legend order should be stable.');
    lgd = legend(ancestor(legendHandles(1), 'axes'), ...
        legendHandles, cellstr(clippedNames), 'Location', 'best');
    assert(isequal(string(lgd.String(:)), expectedOrder), ...
        'MATLAB legend labels should match the deduplicated order.');
    numChecks = numChecks + 1;

    exportFile = [tempname, '.png'];
    cleanupFile = onCleanup(@() delete_if_exists_local(exportFile)); %#ok<NASGU>
    exportgraphics(fig, exportFile, 'Resolution', 96);
    fileInfo = dir(exportFile);
    assert(~isempty(fileInfo) && fileInfo.bytes > 0, ...
        'Exported ray legend figure should be non-empty.');
    numChecks = numChecks + 1;

    results = struct();
    results.case_name = "milestone247_ray_legend_export";
    results.num_checks = numChecks;
    results.export_file_bytes = fileInfo.bytes;
end


function [legendHandles, legendNames, fig] = legend_names_for_styles_local( ...
    styles, clipped, duplicateSegments)
    if nargin < 3
        duplicateSegments = false;
    end

    fig = figure('Visible', 'off');
    ax = axes(fig);
    hold(ax, 'on');
    handles = gobjects(0, 1);
    names = strings(0, 1);

    segmentCount = 1 + double(duplicateSegments);
    for k = 1:height(styles)
        for s = 1:segmentCount
            x = [s - 1, s];
            y = [k, k];
            h = plot(ax, x, y, ...
                'Color', styles.color(k, :), ...
                'LineStyle', char(styles.line_style(k)), ...
                'LineWidth', styles.line_width(k), ...
                'DisplayName', char(styles.display_name(k)));
            handles(end+1, 1) = h; %#ok<AGROW>
            names(end+1, 1) = styles.display_name(k); %#ok<AGROW>
        end

        if clipped(k)
            hClip = plot(ax, segmentCount, k, char(styles.marker(k)), ...
                'Color', styles.color(k, :), ...
                'LineWidth', 1.5, ...
                'MarkerSize', 7, ...
                'DisplayName', 'Clipped ray');
            handles(end+1, 1) = hClip; %#ok<AGROW>
            names(end+1, 1) = "Clipped ray"; %#ok<AGROW>
        end
    end

    [legendHandles, legendNames] = nparaxial_legend_unique_yu(handles, names);
    hold(ax, 'off');
end


function assert_exact_counts_local(actualNames, expectedNames)
    assert(numel(actualNames) == numel(expectedNames), ...
        'Legend should contain only the expected entries.');
    for k = 1:numel(expectedNames)
        assert(count_name_local(actualNames, expectedNames(k)) == 1, ...
            'Legend entry "%s" should appear exactly once.', expectedNames(k));
    end
    assert(isequal(actualNames, expectedNames), ...
        'Legend entries should appear in stable role order.');
end


function n = count_name_local(names, name)
    n = sum(string(names(:)) == string(name));
end


function T = make_prescription_local(elementId, typeName, z, aperture)
    n = numel(string(elementId));
    T = table;
    T.element_id = string(elementId(:));
    T.event_order = (1:n).';
    T.type = string(typeName(:));
    T.z = double(z(:));
    T.aperture_radius = double(aperture(:));
    T.focal_length = Inf(n, 1);
    T.radius_R = Inf(n, 1);
    T.n_before = ones(n, 1);
    T.n_after = ones(n, 1);
    T.enabled = true(n, 1);
    T = nparaxial_validate_prescription_yu(T);
end


function delete_if_exists_local(filename)
    if exist(filename, 'file') == 2
        delete(filename);
    end
end
