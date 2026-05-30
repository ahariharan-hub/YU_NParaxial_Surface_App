function result = demo_nparaxial_check_prescription_yu()
%DEMO_NPARAXIAL_CHECK_PRESCRIPTION_YU Verify validation failure coverage.

    testFolder = fileparts(mfilename('fullpath'));
    rootFolder = fileparts(testFolder);
    addpath(fullfile(rootFolder, 'core'));

    valid = nparaxial_default_prescription_yu();

    badEnabled = valid;
    badEnabled.enabled = string(badEnabled.enabled);
    badEnabled.enabled(1) = "maybe";
    assert_fails_local(@() table_to_prescription_yu(badEnabled), "enabled");

    badMedium = valid;
    badMedium.n_before(2) = 1.2;
    badMedium.n_after(2) = 1.2;
    assert_fails_local(@() table_to_prescription_yu(badMedium), ...
        "Medium continuity");

    result = struct();
    result.case_name = "check_prescription_validation";
    result.invalid_cases = 2;
end


function assert_fails_local(fcn, expectedText)
    didFail = false;
    try
        fcn();
    catch ME
        didFail = true;
        assert(contains(string(ME.message), expectedText), ...
            'Unexpected validation message: %s', ME.message);
    end

    assert(didFail, 'Expected validation call to fail.');
end
