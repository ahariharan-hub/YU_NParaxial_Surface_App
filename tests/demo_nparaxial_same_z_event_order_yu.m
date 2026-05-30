function result = demo_nparaxial_same_z_event_order_yu()
%DEMO_NPARAXIAL_SAME_Z_EVENT_ORDER_YU Verify same-z ordering by event_order.

    rootFolder = fileparts(fileparts(mfilename('fullpath')));
    addpath(fullfile(rootFolder, 'core'));

    zObj = -100;
    zOut = 20;

    element_id = ["L1"; "S1"];
    event_order = [1; 2];
    type = ["thinlens"; "surface"];
    z = [0; 0];
    aperture_radius = [Inf; Inf];
    focal_length = [80; Inf];
    radius_R = [Inf; 50];
    n_before = [1; 1];
    n_after = [1; 1.5];
    enabled = [true; true];
    lensThenSurface = table(element_id, event_order, type, z, ...
        aperture_radius, focal_length, radius_R, n_before, n_after, enabled);

    element_id = ["S1"; "L1"];
    event_order = [1; 2];
    type = ["surface"; "thinlens"];
    z = [0; 0];
    aperture_radius = [Inf; Inf];
    focal_length = [Inf; 80];
    radius_R = [50; Inf];
    n_before = [1; 1.5];
    n_after = [1.5; 1.5];
    enabled = [true; true];
    surfaceThenLens = table(element_id, event_order, type, z, ...
        aperture_radius, focal_length, radius_R, n_before, n_after, enabled);

    orderedA = nparaxial_enabled_elements_yu(lensThenSurface);
    orderedB = nparaxial_enabled_elements_yu(surfaceThenLens);
    assert(orderedA.element_id(1) == "L1", ...
        'Same-z ordering should follow event_order for lens-then-surface.');
    assert(orderedB.element_id(1) == "S1", ...
        'Same-z ordering should follow event_order for surface-then-lens.');

    M_A = nparaxial_system_matrix_yu(lensThenSurface, zObj, zOut);
    M_B = nparaxial_system_matrix_yu(surfaceThenLens, zObj, zOut);
    matrixDifference = norm(M_A - M_B, 'fro');
    assert(matrixDifference > 1e-6, ...
        'Changing same-z event_order should change this noncommuting matrix pair.');

    result = struct();
    result.case_name = "same_z_event_order";
    result.matrix_difference = matrixDifference;
end
