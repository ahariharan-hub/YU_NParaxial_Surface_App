function result = demo_nparaxial_dummy_identity_yu()
%DEMO_NPARAXIAL_DUMMY_IDENTITY_YU Verify dummy elements are identity planes.

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
    basePrescription = table(element_id, event_order, type, z, aperture_radius, ...
        focal_length, radius_R, n_before, n_after, enabled);

    element_id = ["DUMMY"; "L1"];
    event_order = [1; 2];
    type = ["dummy"; "thinlens"];
    z = [-60; 0];
    aperture_radius = [Inf; 75];
    focal_length = [Inf; 80];
    radius_R = [Inf; Inf];
    n_before = [1; 1];
    n_after = [1; 1];
    enabled = [true; true];
    dummyPrescription = table(element_id, event_order, type, z, aperture_radius, ...
        focal_length, radius_R, n_before, n_after, enabled);

    zObj = -120;
    imgBase = nparaxial_solve_image_plane_yu(basePrescription, zObj);
    imgDummy = nparaxial_solve_image_plane_yu(dummyPrescription, zObj);

    assert(norm(imgBase.M_ref - imgDummy.M_ref, 'fro') < 1e-12, ...
        'A dummy plane before the lens should not change M_ref.');
    assert(abs(imgBase.z_img - imgDummy.z_img) < 1e-12, ...
        'A dummy plane before the lens should not change image z.');
    assert(abs(imgBase.m - imgDummy.m) < 1e-12, ...
        'A dummy plane before the lens should not change magnification.');

    E = nparaxial_element_matrix_yu(dummyPrescription(1, :));
    assert(norm(E - eye(2), 'fro') < 1e-12, ...
        'Dummy element matrix should be identity.');

    result = struct();
    result.case_name = "dummy_identity";
    result.z_image = imgDummy.z_img;
    result.magnification = imgDummy.m;
    result.matrix_error = norm(imgBase.M_ref - imgDummy.M_ref, 'fro');
end
