function results = demo_nparaxial_milestone231_ray_fan_yu()
%DEMO_NPARAXIAL_MILESTONE231_RAY_FAN_YU Aperture-limited ray fan tests.

    testFolder = fileparts(mfilename('fullpath'));
    rootFolder = fileparts(testFolder);
    addpath(rootFolder);
    addpath(fullfile(rootFolder, 'core'));

    numChecks = 0;

    rays = nparaxial_make_manual_fan_rays_yu(0, 0, 5, 0.03);
    assert_close_local(rays.u0, linspace(-0.03, 0.03, 5).');
    assert(all(rays.sampling_mode == "Manual fixed-angle fan"));
    numChecks = numChecks + 1;

    p = make_prescription_local("STOP", "stop", 10, 2);
    rays = nparaxial_make_aperture_limited_rays_yu(p, 0, 0, 5, 0.04, 1e-12, 10);
    assert_close_local([rays.u0(1); rays.u0(end)], [-0.2; 0.2]);
    assert(~any(rays.fallback_used));
    assert(~any(rays.fully_vignetted));
    numChecks = numChecks + 1;

    rays = nparaxial_make_aperture_limited_rays_yu(p, 0, 0.5, 5, 0.04, 1e-12, 10);
    assert_close_local([rays.u0(1); rays.u0(end)], [-0.25; 0.15]);
    numChecks = numChecks + 1;

    p = make_prescription_local( ...
        ["STOP1"; "STOP2"], ["stop"; "stop"], [10; 20], [1; 2]);
    rays = nparaxial_make_aperture_limited_rays_yu(p, 0, 0.5, 7, 0.04, 1e-12, 20);
    assert_close_local([rays.u0(1); rays.u0(end)], [-0.125; 0.05]);
    assert(rays.lower_limiter_element_id(1) == "STOP2");
    assert(rays.upper_limiter_element_id(1) == "STOP1");
    numChecks = numChecks + 1;

    p = make_prescription_local( ...
        ["STOP1"; "STOP2"], ["stop"; "stop"], [10; 20], [1; 1]);
    rays = nparaxial_make_aperture_limited_rays_yu(p, 0, 10, 5, 0.04, 1e-12, 20);
    info = rays.Properties.UserData;
    assert(height(rays) == 0, 'Fully vignetted fan should return no rays.');
    assert(info.fully_vignetted);
    assert(contains(info.status_text, "no transmitted aperture-limited ray fan"));
    numChecks = numChecks + 1;

    p = make_prescription_local("D1", "dummy", 10, Inf);
    rays = nparaxial_make_aperture_limited_rays_yu(p, 0, 0, 5, 0.04, 1e-12, 10);
    info = rays.Properties.UserData;
    assert_close_local(rays.u0, linspace(-0.04, 0.04, 5).');
    assert(all(rays.fallback_used));
    assert(info.fallback_used);
    assert(contains(info.status_text, "using manual fixed-angle fan"));
    numChecks = numChecks + 1;

    appSmoke = app_smoke_local(rootFolder);
    if appSmoke == "passed"
        numChecks = numChecks + 1;
    end

    results = struct();
    results.case_name = "milestone231_ray_fan";
    results.num_checks = numChecks;
    results.app_smoke = appSmoke;
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


function assert_close_local(actual, expected)
    actual = double(actual(:));
    expected = double(expected(:));
    assert(isequal(size(actual), size(expected)), ...
        'Arrays have different sizes.');
    assert(max(abs(actual - expected)) < 1e-12, ...
        'Values differ from expected aperture-limited ray fan result.');
end


function status = app_smoke_local(rootFolder)
    status = "skipped";
    if ~usejava('awt')
        return
    end

    oldPath = path;
    cleanupPath = onCleanup(@() path(oldPath)); %#ok<NASGU>
    addpath(rootFolder);
    addpath(fullfile(rootFolder, 'core'));

    app = YU_NParaxialSurface_App_V1();
    cleanupApp = onCleanup(@() delete(app)); %#ok<NASGU>
    app.UIFigure.Visible = 'off';

    rayFanDropdown = find_dropdown_with_item_local( ...
        app.UIFigure, 'Aperture-limited admitted cone');
    rayFanDropdown.Value = 'Aperture-limited admitted cone';
    call_callback_local(rayFanDropdown.ValueChangedFcn, rayFanDropdown);
    drawnow limitrate
    assert_status_contains_local(app, ...
        "Inputs changed. Run Trace to refresh diagnostics.");

    status = "passed";
end


function dropdown = find_dropdown_with_item_local(fig, itemText)
    dropdowns = findall(fig, '-isa', 'matlab.ui.control.DropDown');
    for k = 1:numel(dropdowns)
        if any(string(dropdowns(k).Items) == string(itemText))
            dropdown = dropdowns(k);
            return
        end
    end
    error('Could not find dropdown containing item "%s".', itemText);
end


function call_callback_local(callbackFcn, source)
    if isempty(callbackFcn)
        error('UI callback was empty.');
    end
    if iscell(callbackFcn)
        callbackFcn{1}(source, []);
    else
        callbackFcn(source, []);
    end
end


function assert_status_contains_local(app, token)
    labels = findall(app.UIFigure, '-isa', 'matlab.ui.control.Label');
    texts = strings(numel(labels), 1);
    for k = 1:numel(labels)
        texts(k) = string(labels(k).Text);
    end
    assert(any(contains(texts, token)), ...
        'App status did not contain "%s".', token);
end
