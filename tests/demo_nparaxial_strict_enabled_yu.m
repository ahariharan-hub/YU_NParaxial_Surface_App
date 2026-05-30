function result = demo_nparaxial_strict_enabled_yu()
%DEMO_NPARAXIAL_STRICT_ENABLED_YU Verify strict enabled-column parsing.

    rootFolder = fileparts(fileparts(mfilename('fullpath')));
    addpath(fullfile(rootFolder, 'core'));

    element_id = ["L1"; "DUMMY"];
    event_order = [1; 2];
    type = ["thinlens"; "dummy"];
    z = [0; 10];
    aperture_radius = [75; Inf];
    focal_length = [80; Inf];
    radius_R = [Inf; Inf];
    n_before = [1; 1];
    n_after = [1; 1];
    enabled = ["yes"; "0"];
    prescription = table(element_id, event_order, type, z, aperture_radius, ...
        focal_length, radius_R, n_before, n_after, enabled);

    normalized = nparaxial_validate_prescription_yu(prescription);
    assert(isequal(normalized.enabled, [true; false]), ...
        'Valid string enabled values should parse strictly.');

    badPrescription = prescription;
    badPrescription.enabled = ["maybe"; "true"];
    didFail = false;
    try
        nparaxial_validate_prescription_yu(badPrescription);
    catch
        didFail = true;
    end
    assert(didFail, 'Invalid enabled string should fail validation.');

    badPrescription = prescription;
    badPrescription.enabled = [2; 1];
    didFail = false;
    try
        nparaxial_validate_prescription_yu(badPrescription);
    catch
        didFail = true;
    end
    assert(didFail, 'Numeric enabled values other than 0 or 1 should fail.');

    result = struct();
    result.case_name = "strict_enabled";
    result.num_enabled = sum(normalized.enabled);
end
