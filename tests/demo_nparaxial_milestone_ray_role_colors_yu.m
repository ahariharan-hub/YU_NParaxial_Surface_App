function results = demo_nparaxial_milestone_ray_role_colors_yu()
%DEMO_NPARAXIAL_MILESTONE_RAY_ROLE_COLORS_YU Ray role color tests.

    testFolder = fileparts(mfilename('fullpath'));
    rootFolder = fileparts(testFolder);
    addpath(rootFolder);
    addpath(fullfile(rootFolder, 'core'));

    blue = [0 0.4470 0.7410];
    red = [0.8500 0.0000 0.0000];
    green = [0.0000 0.6000 0.0000];
    gray = [0.56 0.56 0.56];

    numChecks = 0;

    style = nparaxial_ray_role_style_yu("UMR", false);
    assert(style.role == "UMR");
    assert_color_local(style.color, blue, 'UMR should be blue.');
    assert(style.display_name == "UMR");
    numChecks = numChecks + 1;

    style = nparaxial_ray_role_style_yu("CR", false);
    assert(style.role == "CR");
    assert_color_local(style.color, red, 'CR should be red.');
    assert(style.display_name == "CR");
    numChecks = numChecks + 1;

    style = nparaxial_ray_role_style_yu("LMR", false);
    assert(style.role == "LMR");
    assert_color_local(style.color, green, 'LMR should be green.');
    assert(style.display_name == "LMR");
    numChecks = numChecks + 1;

    style = nparaxial_ray_role_style_yu("intermediate", false);
    assert(style.role == "intermediate");
    assert_color_local(style.color, gray, ...
        'Intermediate rays should use neutral gray.');
    numChecks = numChecks + 1;

    roleNames = ["UMR"; "CR"; "LMR"];
    for k = 1:numel(roleNames)
        baseStyle = nparaxial_ray_role_style_yu(roleNames(k), false);
        clippedStyle = nparaxial_ray_role_style_yu(roleNames(k), true);
        assert_color_local(clippedStyle.color, baseStyle.color, ...
            'Clipped role ray should keep its role color.');
        assert(clippedStyle.line_style ~= baseStyle.line_style || ...
            clippedStyle.marker ~= baseStyle.marker, ...
            'Clipped role ray should change line style or marker.');
    end
    numChecks = numChecks + 1;

    p = make_prescription_local("STOP", "stop", 10, 2);
    rays = nparaxial_make_aperture_limited_rays_yu( ...
        p, 0, 0, 3, 0.04, 1e-12, 10);
    styles = nparaxial_ray_role_style_yu(rays, false(height(rays), 1));
    assert(isequal(styles.role, ["LMR"; "CR"; "UMR"]), ...
        '3-ray aperture fan roles should be LMR/CR/UMR.');
    assert_color_local(styles.color(1, :), green, ...
        '3-ray lower aperture fan ray should be green.');
    assert_color_local(styles.color(2, :), red, ...
        '3-ray center aperture fan ray should be red.');
    assert_color_local(styles.color(3, :), blue, ...
        '3-ray upper aperture fan ray should be blue.');
    numChecks = numChecks + 1;

    rays = nparaxial_make_aperture_limited_rays_yu( ...
        p, 0, 0, 5, 0.04, 1e-12, 10);
    styles = nparaxial_ray_role_style_yu(rays, false(height(rays), 1));
    assert(isequal(styles.role, ...
        ["LMR"; "intermediate"; "CR"; "intermediate"; "UMR"]), ...
        '5-ray aperture fan roles should mark only LMR/CR/UMR.');
    assert_color_local(styles.color(1, :), green, ...
        '5-ray lower aperture fan ray should be green.');
    assert_color_local(styles.color(2, :), gray, ...
        '5-ray intermediate aperture fan ray should be gray.');
    assert_color_local(styles.color(3, :), red, ...
        '5-ray center aperture fan ray should be red.');
    assert_color_local(styles.color(4, :), gray, ...
        '5-ray intermediate aperture fan ray should be gray.');
    assert_color_local(styles.color(5, :), blue, ...
        '5-ray upper aperture fan ray should be blue.');
    numChecks = numChecks + 1;

    stopRays = nparaxial_make_stop_sampled_rays_yu(p, 0, 0.25, 10, 2, 5);
    stopStyles = nparaxial_ray_role_style_yu( ...
        stopRays, false(height(stopRays), 1));
    assert(isequal(stopStyles.role, ...
        ["LMR"; "intermediate"; "CR"; "intermediate"; "UMR"]), ...
        'Stop-targeted fan roles should mark LMR/CR/UMR.');
    assert_color_local(stopStyles.color(1, :), green, ...
        'Stop lower marginal ray should be green.');
    assert_color_local(stopStyles.color(3, :), red, ...
        'Stop chief ray should be red.');
    assert_color_local(stopStyles.color(5, :), blue, ...
        'Stop upper marginal ray should be blue.');
    numChecks = numChecks + 1;

    results = struct();
    results.case_name = "ray_role_colors";
    results.num_checks = numChecks;
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


function assert_color_local(actual, expected, message)
    actual = double(actual(:)).';
    expected = double(expected(:)).';
    assert(isequal(size(actual), size(expected)), ...
        'Color arrays have different sizes.');
    assert(max(abs(actual - expected)) < 1e-12, message);
end
