function result = demo_nparaxial_single_thin_lens_yu()
%DEMO_NPARAXIAL_SINGLE_THIN_LENS_YU Single thin-lens finite conjugate demo.

    rootFolder = fileparts(fileparts(mfilename('fullpath')));
    addpath(fullfile(rootFolder, 'core'));

    element_id = "L1";
    event_order = 1;
    type = "thinlens";
    z = 0;
    aperture_radius = 75;
    focal_length = 80;
    radius_R = Inf;
    n_before = 1;
    n_after = 1;
    enabled = true;
    prescription = table(element_id, event_order, type, z, aperture_radius, ...
        focal_length, radius_R, n_before, n_after, enabled);

    zObj = -120;
    yObj = 4;
    img = nparaxial_solve_image_plane_yu(prescription, zObj);

    expectedZ = 240;
    expectedM = -2;
    assert(abs(img.z_img - expectedZ) < 1e-10, ...
        'Single thin-lens image z did not match the analytic value.');
    assert(abs(img.m - expectedM) < 1e-12, ...
        'Single thin-lens magnification did not match the analytic value.');

    rays = table;
    rays.name = ["lower_marginal"; "chief"; "upper_marginal"];
    rays.z0 = repmat(zObj, 3, 1);
    rays.y0 = repmat(yObj, 3, 1);
    rays.u0 = [-0.03; 0; 0.03];

    bundle = nparaxial_trace_bundle_yu(rays, prescription, img.z_img);
    yf = [bundle.yf].';
    assert(all([bundle.trc].'), 'All single-lens demo rays should trace.');
    assert(max(abs(yf - expectedM*yObj)) < 1e-10, ...
        'Single thin-lens rays did not meet at the solved image plane.');

    result = struct();
    result.case_name = "single_thin_lens";
    result.z_image = img.z_img;
    result.magnification = img.m;
    result.max_image_error = max(abs(yf - expectedM*yObj));
end
