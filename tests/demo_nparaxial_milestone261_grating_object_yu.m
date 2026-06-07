function results = demo_nparaxial_milestone261_grating_object_yu()
%DEMO_NPARAXIAL_MILESTONE261_GRATING_OBJECT_YU Grating source checks.

    testFolder = fileparts(mfilename('fullpath'));
    rootFolder = fileparts(testFolder);
    addpath(rootFolder);
    addpath(fullfile(rootFolder, 'core'));
    addpath(fullfile(rootFolder, 'examples'));

    numChecks = 0;

    zObj = -120;
    yObj = 0;
    wavelengthUm = 0.193;
    periodUm = 0.500;
    orders = (-3:3).';

    [rays, info] = nparaxial_make_grating_order_rays_yu( ...
        zObj, yObj, wavelengthUm, periodUm, orders, 0, 1, 1);

    assert(istable(rays) && height(rays) > 0, ...
        'Grating helper should return a nonempty ray table.');
    numChecks = numChecks + 1;

    requiredColumns = ["z0", "y0", "u0"];
    assert(all(ismember(requiredColumns, ...
        string(rays.Properties.VariableNames))), ...
        'Grating ray table should expose z0, y0, and u0 columns.');
    numChecks = numChecks + 1;

    assert(istable(info.order_table) && height(info.order_table) == numel(orders) && ...
        info.n_nonpropagating > 0 && ...
        any(~info.order_table.is_propagating), ...
        'Grating info should report non-propagating requested orders.');
    numChecks = numChecks + 1;

    zeroMask = rays.diffraction_order == 0;
    assert(nnz(zeroMask) == 1 && abs(rays.u0(zeroMask)) < 1e-14 && ...
        abs(rays.theta_m_deg(zeroMask)) < 1e-12, ...
        'Normal-incidence m = 0 order should launch at zero angle.');
    numChecks = numChecks + 1;

    posMask = rays.diffraction_order == 1;
    negMask = rays.diffraction_order == -1;
    assert(nnz(posMask) == 1 && nnz(negMask) == 1 && ...
        abs(rays.u0(posMask) + rays.u0(negMask)) < 1e-14 && ...
        rays.u0(posMask) > 0 && rays.u0(negMask) < 0, ...
        'Positive and negative normal-incidence orders should be symmetric.');
    numChecks = numChecks + 1;

    prescription = nparaxial_default_prescription_yu("two thin lenses");
    prescription = nparaxial_validate_prescription_yu(prescription);
    img = nparaxial_solve_image_plane_yu(prescription, zObj, 1e-12);
    zFinal = img.trace_z_final;
    bundle = nparaxial_trace_bundle_yu(rays, prescription, zFinal);
    assert(numel(bundle) == height(rays) && ...
        all(string({bundle.name}.') == rays.name), ...
        'Grating ray table should be accepted by nparaxial_trace_bundle_yu.');
    numChecks = numChecks + 1;

    assert(any([bundle.trc].'), ...
        'At least one propagating grating order should trace through the default system.');
    numChecks = numChecks + 1;

    exampleOut = demo_grating_object_paraxial_yu(false, false);
    assert(isstruct(exampleOut) && istable(exampleOut.rays) && ...
        numel(exampleOut.bundle) == height(exampleOut.rays) && ...
        isempty(exampleOut.figure), ...
        'Grating example should run without launching an app UI.');
    numChecks = numChecks + 1;

    results = struct();
    results.case_name = "milestone261_grating_object";
    results.num_checks = numChecks;
    results.propagating_orders = height(rays);
    results.nonpropagating_orders = info.n_nonpropagating;
    results.traced_orders = sum([bundle.trc].');
end
