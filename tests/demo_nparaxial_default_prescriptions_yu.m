function result = demo_nparaxial_default_prescriptions_yu()
%DEMO_NPARAXIAL_DEFAULT_PRESCRIPTIONS_YU Verify built-in presets validate.

    testFolder = fileparts(mfilename('fullpath'));
    rootFolder = fileparts(testFolder);
    addpath(fullfile(rootFolder, 'core'));

    presetNames = [
        "Single thin lens"
        "Two thin lenses"
        "Two-surface thick lens"
        "Stop clipping demo"
        "Homogeneous translation / free-space propagation"
    ];

    rowCounts = zeros(numel(presetNames), 1);
    for k = 1:numel(presetNames)
        prescription = nparaxial_default_prescription_yu(presetNames(k));
        prescription = table_to_prescription_yu(prescription);
        rowCounts(k) = height(prescription);
    end

    result = struct();
    result.case_name = "default_prescriptions";
    result.presets = presetNames;
    result.row_counts = rowCounts;
end
