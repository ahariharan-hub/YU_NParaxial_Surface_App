function results = demo_nparaxial_milestone248_image_classification_translation_yu()
%DEMO_NPARAXIAL_MILESTONE248_IMAGE_CLASSIFICATION_TRANSLATION_YU Image tests.

    testFolder = fileparts(mfilename('fullpath'));
    rootFolder = fileparts(testFolder);
    addpath(rootFolder);
    addpath(fullfile(rootFolder, 'core'));

    numChecks = 0;

    L = 100;
    img = nparaxial_classify_image_plane_yu([1 L; 0 1], L, 1e-12);
    assert(img.type == "finite virtual image", ...
        'Pure translation should classify as finite virtual image.');
    assert(img.is_finite && img.is_virtual && ~img.is_real, ...
        'Pure translation should be finite virtual, not real.');
    assert_close_local(img.x_from_reference, -L, ...
        'Pure translation x_from_reference');
    assert_close_local(img.z_image, 0, 'Pure translation z_image');
    numChecks = numChecks + 1;

    p = nparaxial_default_prescription_yu("single thin lens");
    realImg = nparaxial_solve_image_plane_yu(p, -120);
    assert(realImg.type == "finite real image", ...
        'Single thin lens should classify as finite real image.');
    assert(realImg.is_finite && realImg.is_real && ~realImg.is_virtual, ...
        'Single thin lens should be finite real, not virtual.');
    assert_close_local(realImg.z_img, 240, 'Single thin lens z_img');
    assert_close_local(realImg.m, -2, 'Single thin lens magnification');
    numChecks = numChecks + 1;

    afocalImg = nparaxial_classify_image_plane_yu([1 25; -0.04 0], 50, 1e-12);
    assert(afocalImg.type == "image at infinity / no finite image", ...
        'D = 0 should classify as image at infinity / no finite image.');
    assert(~afocalImg.is_finite && afocalImg.is_at_infinity, ...
        'D = 0 should not report a finite image.');
    assert(contains(afocalImg.message, "D is approximately zero"), ...
        'D = 0 classification should explain the unsolved B + xD condition.');
    numChecks = numChecks + 1;

    twoLens = nparaxial_solve_image_plane_yu( ...
        nparaxial_default_prescription_yu("two thin lenses"), -120);
    assert_close_local(twoLens.z_img, 232, 'Two-thin-lens z_img');
    assert(twoLens.is_finite, ...
        'Two-thin-lens preset should keep a finite solved image plane.');
    numChecks = numChecks + 1;

    translationPreset = nparaxial_default_prescription_yu( ...
        "Homogeneous translation / free-space propagation");
    translationPreset = table_to_prescription_yu(translationPreset);
    assert(height(translationPreset) == 1, ...
        'Translation preset should load one dummy output plane.');
    assert(translationPreset.type(1) == "dummy", ...
        'Translation preset should use a dummy plane.');
    numChecks = numChecks + 1;

    poweredMask = translationPreset.type == "thinlens" | ...
        translationPreset.type == "surface";
    assert(~any(poweredMask), ...
        'Translation preset should not contain powered elements.');
    assert(all(isinf(translationPreset.aperture_radius)), ...
        'Translation preset should not introduce finite aperture clipping.');
    assert(all(isinf(translationPreset.focal_length)) && ...
        all(isinf(translationPreset.radius_R)), ...
        'Translation preset power columns should be infinite.');
    numChecks = numChecks + 1;

    presetImg = nparaxial_solve_image_plane_yu(translationPreset, 0);
    assert(presetImg.type == "finite virtual image", ...
        'Translation preset should report a finite virtual image.');
    assert_close_local(presetImg.x_after_ref, -L, ...
        'Translation preset x_after_ref');
    assert_close_local(presetImg.z_img, 0, 'Translation preset z_img');
    assert_close_local(presetImg.trace_z_final, L, ...
        'Translation preset forward trace endpoint');
    numChecks = numChecks + 1;

    results = struct();
    results.case_name = "milestone248_image_classification_translation";
    results.num_checks = numChecks;
    results.translation_image_type = presetImg.type;
end


function assert_close_local(actual, expected, label)
    assert(abs(double(actual) - double(expected)) < 1e-10, ...
        '%s differs from expected value.', label);
end
