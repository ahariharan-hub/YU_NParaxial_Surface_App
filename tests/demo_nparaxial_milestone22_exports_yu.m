function result = demo_nparaxial_milestone22_exports_yu()
%DEMO_NPARAXIAL_MILESTONE22_EXPORTS_YU Validate export/report helpers.

    testFolder = fileparts(mfilename('fullpath'));
    rootFolder = fileparts(testFolder);
    addpath(fullfile(rootFolder, 'core'));

    test_export_table_csv_local(testFolder);
    test_combined_report_local();
    test_field_aware_diagnostics_local();

    result = struct();
    result.case_name = "milestone22_exports";
    result.num_checks = 3;
end


function test_export_table_csv_local(testFolder)
    T = table;
    T.index = [1; 2; 3];
    T.value = [10.5; 20.5; 30.5];

    filename = [tempname(testFolder), '.csv'];
    cleanup = onCleanup(@() cleanup_file_local(filename));

    nparaxial_export_table_csv_yu(T, filename);
    loaded = readtable(filename);
    assert(isequal(loaded.index, T.index), ...
        'CSV export helper did not preserve index values.');
    assert(max(abs(loaded.value - T.value)) < 1e-12, ...
        'CSV export helper did not preserve numeric values.');
end


function test_combined_report_local()
    zObj = -120;
    p = nparaxial_default_prescription_yu("two thin lenses");
    img = nparaxial_solve_image_plane_yu(p, zObj);
    diagnostics = nparaxial_field_diagnostics_yu(p, zObj, img.z_img, 2.5);

    quantity = ["A_ref"; "B_ref"; "C_ref"; "D_ref"];
    value = [img.A_ref; img.B_ref; img.C_ref; img.D_ref];
    matrixTable = table(quantity, value);
    lines = nparaxial_combined_report_yu( ...
        p, matrixTable, img, diagnostics, "summary sentinel");
    text = strjoin(string(lines), newline);

    requiredTokens = [
        "Prescription"
        "System matrix"
        "Image plane"
        "Cardinal"
        "Aperture stop"
        "Chief/marginal"
        "Invariant"
        "Diagnostic field height"
        "Vignetting intervals"
        "Limitations/warnings"
        "Off-axis vignetting interval diagnostics are first-order meridional diagnostics"
    ];
    for k = 1:numel(requiredTokens)
        assert(contains(text, requiredTokens(k)), ...
            'Combined report missing token "%s".', requiredTokens(k));
    end
end


function test_field_aware_diagnostics_local()
    zObj = -120;
    p = nparaxial_default_prescription_yu("two thin lenses");
    img = nparaxial_solve_image_plane_yu(p, zObj);

    axial = nparaxial_field_diagnostics_yu(p, zObj, img.z_img, 0);
    offAxis = nparaxial_field_diagnostics_yu(p, zObj, img.z_img, 4);

    assert(axial.is_axial, 'y_field = 0 should be labeled axial.');
    assert(strlength(axial.off_axis_warning) == 0, ...
        'Axial diagnostics should not carry off-axis warning.');
    assert(~offAxis.is_axial, 'Nonzero y_field should be labeled off-axis.');
    assert(contains(offAxis.off_axis_warning, ...
        "Off-axis vignetting interval diagnostics are first-order meridional diagnostics"), ...
        'Off-axis diagnostics should report first-order vignetting interval note.');
    assert(offAxis.stop.selected_event_index == axial.stop.selected_event_index, ...
        'Off-axis diagnostics should keep the axial-selected stop.');
    assert(~isempty(offAxis.vignetting), ...
        'Off-axis diagnostics should include vignetting intervals.');
    assert(all(offAxis.chief_marginal.rays.y0 == 4), ...
        'Chief/marginal rays should use the selected diagnostic field height.');
end


function cleanup_file_local(filename)
    if exist(filename, 'file')
        delete(filename);
    end
end
