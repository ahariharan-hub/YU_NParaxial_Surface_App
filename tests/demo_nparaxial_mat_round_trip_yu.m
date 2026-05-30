function result = demo_nparaxial_mat_round_trip_yu()
%DEMO_NPARAXIAL_MAT_ROUND_TRIP_YU Verify MAT prescription round trip.

    testFolder = fileparts(mfilename('fullpath'));
    rootFolder = fileparts(testFolder);
    addpath(fullfile(rootFolder, 'core'));
    addpath(testFolder);

    prescription = nparaxial_default_prescription_yu("stop clipping demo");
    filename = [tempname(testFolder), '.mat'];
    cleanup = onCleanup(@() cleanup_file_local(filename));

    save_prescription_mat_yu(prescription, filename);
    loaded = load_prescription_mat_yu(filename);
    assert_prescriptions_equal_yu(prescription, loaded);

    result = struct();
    result.case_name = "mat_round_trip";
    result.rows = height(loaded);
end


function cleanup_file_local(filename)
    if exist(filename, 'file')
        delete(filename);
    end
end
