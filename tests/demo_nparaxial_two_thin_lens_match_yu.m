function result = demo_nparaxial_two_thin_lens_match_yu()
%DEMO_NPARAXIAL_TWO_THIN_LENS_MATCH_YU Two-lens app equivalent demo.

    rootFolder = fileparts(fileparts(mfilename('fullpath')));
    addpath(fullfile(rootFolder, 'core'));

    element_id = ["L1"; "STOP"; "L2"];
    event_order = [1; 2; 3];
    type = ["thinlens"; "stop"; "thinlens"];
    z = [0; 100; 260];
    aperture_radius = [75; 8; 95];
    focal_length = [80; Inf; 70];
    radius_R = [Inf; Inf; Inf];
    n_before = [1; 1; 1];
    n_after = [1; 1; 1];
    enabled = [true; true; true];
    prescription = table(element_id, event_order, type, z, aperture_radius, ...
        focal_length, radius_R, n_before, n_after, enabled);

    zObj = -120;
    img = nparaxial_solve_image_plane_yu(prescription, zObj);

    T = @(d) [1, d; 0, 1];
    L = @(f) [1, 0; -1/f, 1];
    MrefExpected = L(70) * T(260 - 100) * eye(2) * ...
        T(100 - 0) * L(80) * T(0 - zObj);
    xExpected = -MrefExpected(1, 2) / MrefExpected(2, 2);
    zExpected = 260 + xExpected;
    MimgExpected = T(xExpected) * MrefExpected;

    assert(norm(img.M_ref - MrefExpected, 'fro') < 1e-10, ...
        'Two-thin-lens reference matrix does not match the old app sequence.');
    assert(abs(img.z_img - zExpected) < 1e-10, ...
        'Two-thin-lens image z does not match the old app sequence.');
    assert(abs(img.m - MimgExpected(1, 1)) < 1e-12, ...
        'Two-thin-lens magnification does not match the old app sequence.');

    rays = nparaxial_make_stop_sampled_rays_yu( ...
        prescription, zObj, 5, 100, 8, 9);
    bundle = nparaxial_trace_bundle_yu(rays, prescription, img.z_img);
    assert(all([bundle.trc].'), 'Default two-thin-lens stop-targeted rays should trace.');

    blockedRay = table;
    blockedRay.name = "blocked_at_stop";
    blockedRay.z0 = zObj;
    blockedRay.y0 = 0;
    blockedRay.u0 = 0.13;
    blockedBundle = nparaxial_trace_bundle_yu(blockedRay, prescription, img.z_img);
    blockedRes = blockedBundle(1).res;
    assert(~blockedBundle(1).trc, 'A ray exceeding the stop aperture should block.');
    assert(abs(blockedRes.blocked_at_z - 100) < 1e-12, ...
        'Blocked ray should report the aperture stop z.');
    assert(isfinite(blockedRes.blocked_aperture) && ...
        abs(blockedRes.blocked_aperture - 8) < 1e-12, ...
        'Blocked ray should report the finite stop aperture.');

    result = struct();
    result.case_name = "two_thin_lens_match";
    result.z_image = img.z_img;
    result.magnification = img.m;
    result.matrix_error = norm(img.M_ref - MrefExpected, 'fro');
end
