function results = demo_nparaxial_milestone264_conceptual_cases_yu()
%DEMO_NPARAXIAL_MILESTONE264_CONCEPTUAL_CASES_YU Conceptual default-case checks.
%
% Milestone 2.6.4 adds compact educational cases without changing the
% paraxial engine, matrix formulas, pupil formulas, V2 UI structure, or V1
% artifacts.

    testFolder = fileparts(mfilename('fullpath'));
    rootFolder = fileparts(testFolder);
    addpath(rootFolder);
    addpath(fullfile(rootFolder, 'core'));
    addpath(fullfile(rootFolder, 'workflows'));
    addpath(fullfile(rootFolder, 'plotting'));

    numChecks = 0;
    cases = nparaxial_default_case_library_yu();
    keys = string({cases.key}).';

    expectedKeys = [
        "basic_single_lens_m_minus_2"
        "basic_negative_lens_virtual_image"
        "basic_phase_space_shear_kick"
        "telecentric_near_object_space_limit"
        "thick_plane_parallel_plate"
        ];

    assert(all(ismember(expectedKeys, keys)), ...
        'Milestone 2.6.4 conceptual case keys should be present.');
    assert(numel(keys) == numel(unique(keys)), ...
        'Default case keys should remain unique.');
    numChecks = numChecks + 2;

    for k = 1:numel(expectedKeys)
        caseDef = nparaxial_get_default_case_yu(expectedKeys(k));
        nparaxial_validate_prescription_yu(caseDef.prescription);
        assert(caseDef.object_conjugate == "finite", ...
            'Milestone 2.6.4 case %s should be finite-conjugate metadata.', ...
            caseDef.key);
        assert(caseDef.object_z == 0 && caseDef.launch_z == 0, ...
            'Milestone 2.6.4 case %s should launch from z=0.', ...
            caseDef.key);
        numChecks = numChecks + 3;
    end

    img = image_for_case_local("basic_single_lens_m_minus_2");
    assert_close_local(img.z_img, 450, ...
        'single lens m=-2 image location');
    assert_close_local(img.m, -2, ...
        'single lens m=-2 magnification');
    numChecks = numChecks + 2;

    img = image_for_case_local("basic_negative_lens_virtual_image");
    assert(img.is_virtual, ...
        'negative lens finite-conjugate case should form a virtual image.');
    assert_close_local(img.z_img, 400/3, ...
        'negative lens virtual image location');
    assert_close_local(img.m, 1/3, ...
        'negative lens virtual-image magnification');
    numChecks = numChecks + 3;

    img = image_for_case_local("basic_phase_space_shear_kick");
    assert_close_local(img.z_img, 400, ...
        'phase-space shear/kick image location');
    assert_close_local(img.m, -1, ...
        'phase-space shear/kick magnification');
    numChecks = numChecks + 2;

    img = image_for_case_local("telecentric_near_object_space_limit");
    assert_close_local(img.z_img, 250, ...
        'near object-space telecentric image location');
    assert_close_local(img.m, -1.5, ...
        'near object-space telecentric magnification');
    numChecks = numChecks + 2;

    plate = nparaxial_get_default_case_yu("thick_plane_parallel_plate");
    elements = nparaxial_enabled_elements_yu(plate.prescription);
    M = nparaxial_system_matrix_yu( ...
        plate.prescription, plate.launch_z, max(elements.z));
    assert_close_local(M(2, 1), 0, ...
        'plane-parallel plate net optical power C');
    assert_close_local(M(2, 2), 1, ...
        'plane-parallel plate output angle scaling D');
    numChecks = numChecks + 2;

    assert(has_dummy_local("basic_single_lens_m_minus_2", "IMG"), ...
        'Single-lens magnifier should include IMG dummy plane.');
    assert(has_dummy_local("basic_negative_lens_virtual_image", "REF_OUT"), ...
        'Negative-lens virtual-image case should include REF_OUT dummy plane.');
    assert(has_dummy_local("telecentric_near_object_space_limit", "IMG"), ...
        'Near telecentric case should include IMG dummy plane.');
    assert(has_dummy_local("thick_plane_parallel_plate", "REF_OUT"), ...
        'Plane-parallel plate should include REF_OUT dummy plane.');
    numChecks = numChecks + 4;

    results = struct();
    results.case_name = "milestone264_conceptual_cases";
    results.num_checks = numChecks;
    results.case_count = numel(cases);
    results.added_keys = expectedKeys;
    results.single_lens_m_minus_2_z = 450;
    results.negative_lens_virtual_z = 400/3;
    results.near_telecentric_z = 250;
    results.plane_parallel_plate_C = M(2, 1);
    results.plane_parallel_plate_D = M(2, 2);
end


function img = image_for_case_local(key)
    caseDef = nparaxial_get_default_case_yu(key);
    img = nparaxial_solve_image_plane_yu( ...
        caseDef.prescription, caseDef.launch_z, 1e-12);
end


function tf = has_dummy_local(key, elementId)
    caseDef = nparaxial_get_default_case_yu(key);
    p = nparaxial_validate_prescription_yu(caseDef.prescription);
    tf = any(p.type == "dummy" & p.element_id == string(elementId));
end


function assert_close_local(actual, expected, label)
    assert(abs(double(actual) - double(expected)) < 1e-9, ...
        '%s expected %.12g, got %.12g.', label, expected, actual);
end
