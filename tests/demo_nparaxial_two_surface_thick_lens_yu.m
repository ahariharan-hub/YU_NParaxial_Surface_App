function result = demo_nparaxial_two_surface_thick_lens_yu()
%DEMO_NPARAXIAL_TWO_SURFACE_THICK_LENS_YU Two refracting surfaces demo.

    rootFolder = fileparts(fileparts(mfilename('fullpath')));
    addpath(fullfile(rootFolder, 'core'));

    element_id = ["S1"; "S2"];
    event_order = [1; 2];
    type = ["surface"; "surface"];
    z = [0; 8];
    aperture_radius = [25; 25];
    focal_length = [Inf; Inf];
    radius_R = [50; -50];
    n_before = [1; 1.5];
    n_after = [1.5; 1];
    enabled = [true; true];
    prescription = table(element_id, event_order, type, z, aperture_radius, ...
        focal_length, radius_R, n_before, n_after, enabled);

    zObj = -140;
    yObj = 3;
    img = nparaxial_solve_image_plane_yu(prescription, zObj);

    T = @(d) [1, d; 0, 1];
    S = @(n1, n2, R) [1, 0; (n1 - n2)/(n2*R), n1/n2];
    MrefExpected = S(1.5, 1, -50) * T(8) * ...
        S(1, 1.5, 50) * T(0 - zObj);

    assert(norm(img.M_ref - MrefExpected, 'fro') < 1e-10, ...
        'Two-surface thick-lens matrix did not match direct surface product.');
    assert(img.isFinite, 'Two-surface thick-lens demo should have a finite image.');

    rays = table;
    rays.name = ["lower_marginal"; "chief"; "upper_marginal"];
    rays.z0 = repmat(zObj, 3, 1);
    rays.y0 = repmat(yObj, 3, 1);
    rays.u0 = [-0.02; 0; 0.02];
    bundle = nparaxial_trace_bundle_yu(rays, prescription, img.z_img);
    yf = [bundle.yf].';
    assert(all([bundle.trc].'), 'All two-surface demo rays should trace.');
    assert(max(abs(yf - img.m*yObj)) < 1e-9, ...
        'Two-surface rays did not meet at the solved image plane.');

    result = struct();
    result.case_name = "two_surface_thick_lens";
    result.z_image = img.z_img;
    result.magnification = img.m;
    result.matrix_error = norm(img.M_ref - MrefExpected, 'fro');
    result.max_image_error = max(abs(yf - img.m*yObj));
end
