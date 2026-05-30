function result = demo_nparaxial_csv_round_trip_yu()
%DEMO_NPARAXIAL_CSV_ROUND_TRIP_YU Verify CSV prescription round trip.

    testFolder = fileparts(mfilename('fullpath'));
    rootFolder = fileparts(testFolder);
    addpath(fullfile(rootFolder, 'core'));
    addpath(testFolder);

    prescription = round_trip_test_prescription_local();
    filename = [tempname(testFolder), '.csv'];
    cleanup = onCleanup(@() cleanup_file_local(filename));

    save_prescription_csv_yu(prescription, filename);
    loaded = load_prescription_csv_yu(filename);
    assert_prescriptions_equal_yu(prescription, loaded);

    result = struct();
    result.case_name = "csv_round_trip";
    result.rows = height(loaded);
end


function prescription = round_trip_test_prescription_local()
    prescription = table;
    prescription.element_id = ["D0"; "L1"; "STOP"; "S1"; "S2"; "D1"];
    prescription.event_order = (1:6).';
    prescription.type = ["dummy"; "thinlens"; "stop"; "surface"; "surface"; "dummy"];
    prescription.z = [-20; 0; 25; 50; 58; 70];
    prescription.aperture_radius = [Inf; 50; 8; 35; 35; Inf];
    prescription.focal_length = [Inf; 100; Inf; Inf; Inf; Inf];
    prescription.radius_R = [Inf; Inf; Inf; 80; -80; Inf];
    prescription.n_before = [1; 1; 1; 1; 1.5; 1];
    prescription.n_after = [1; 1; 1; 1.5; 1; 1];
    prescription.enabled = [true; true; true; true; true; true];
    prescription = nparaxial_validate_prescription_yu(prescription);
end


function cleanup_file_local(filename)
    if exist(filename, 'file')
        delete(filename);
    end
end
