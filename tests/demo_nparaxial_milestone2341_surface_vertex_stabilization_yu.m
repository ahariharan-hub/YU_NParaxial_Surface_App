function results = demo_nparaxial_milestone2341_surface_vertex_stabilization_yu()
%DEMO_NPARAXIAL_MILESTONE2341_SURFACE_VERTEX_STABILIZATION_YU Edge tests.

    testFolder = fileparts(mfilename('fullpath'));
    rootFolder = fileparts(testFolder);
    addpath(rootFolder);
    addpath(fullfile(rootFolder, 'core'));

    numChecks = 0;

    test_normal_argument_clamping_local();
    numChecks = numChecks + 1;

    test_snell_argument_clamping_local();
    numChecks = numChecks + 1;

    test_event_invalid_normal_local();
    numChecks = numChecks + 1;

    test_event_surface_tir_local();
    numChecks = numChecks + 1;

    test_nonfinite_snell_argument_local();
    numChecks = numChecks + 1;

    test_worst_surface_vertex_delta_summary_local();
    numChecks = numChecks + 1;

    results = struct();
    results.case_name = "milestone2341_surface_vertex_stabilization";
    results.num_checks = numChecks;
end


function test_normal_argument_clamping_local()
    tol = 1e-6;
    diag = nparaxial_surface_vertex_scalar_validity_yu( ...
        1 + 0.5*tol, 0, 1, 1.5, 1, [], tol);

    assert(diag.surface_sasin_clamped_flag, ...
        'Normal argument just outside range should be clamped.');
    assert(diag.surface_normal_argument_clamped == 1, ...
        'Positive normal argument should clamp exactly to +1.');
    assert(~diag.invalid_surface_normal_flag, ...
        'Normal argument within tolerance should not be invalid.');
    assert(ismember(diag.warning_level, ["warning", "severe"]), ...
        'Near-boundary clamped normal should produce at least warning.');
    assert(contains(diag.note, "Normal argument clamped"), ...
        'Note should mention normal-argument clamping.');
    assert(contains(diag.note, "near grazing"), ...
        'Note should preserve near-grazing condition alongside clamping.');
end


function test_snell_argument_clamping_local()
    tol = 1e-6;
    n1 = 1.5;
    n2 = 1;
    uIn = asin((1 + 0.5*tol) / (n1/n2));
    diag = nparaxial_surface_vertex_scalar_validity_yu( ...
        0, uIn, n1, n2, 10, [], tol);

    assert(diag.snell_clamped_flag, ...
        'Snell argument just outside range should be clamped.');
    assert(diag.surface_snell_argument_clamped == 1, ...
        'Positive Snell argument should clamp exactly to +1.');
    assert(~diag.tir_flag, ...
        'Snell argument within tolerance should not be TIR.');
    assert(contains(diag.note, "Snell argument clamped"), ...
        'Note should mention Snell-argument clamping.');
end


function test_event_invalid_normal_local()
    p = prescription_local("S_invalid", 1, "surface", 10, ...
        Inf, Inf, 1, 1, 1.5);
    rays = ray_table_local("invalid_normal", 0, 2, 0);
    validity = nparaxial_paraxial_validity_yu( ...
        bundle_set_local(rays, p, 10), p);
    evt = validity.event_table;

    assert(evt.diagnostic_type(1) == "spherical_vertex_scalar", ...
        'Finite-radius event should use spherical vertex diagnostic.');
    assert(evt.invalid_surface_normal_flag(1), ...
        'Event-level invalid normal flag should be true.');
    assert(isnan(evt.u_out_exact_vertex(1)), ...
        'Invalid normal event should not fabricate exact output.');
    assert(isnan(evt.delta_u_vertex_scalar(1)), ...
        'Invalid normal event should not fabricate vertex delta.');
    assert(evt.warning_level(1) == "severe", ...
        'Invalid normal event should force severe warning.');
end


function test_event_surface_tir_local()
    p = prescription_local("S_tir", 1, "surface", 10, ...
        Inf, Inf, 10, 1.5, 1);
    rays = ray_table_local("tir", 0, -10, 1.0);
    validity = nparaxial_paraxial_validity_yu( ...
        bundle_set_local(rays, p, 10), p);
    evt = validity.event_table;

    assert(evt.diagnostic_type(1) == "spherical_vertex_scalar", ...
        'Finite-radius TIR event should use spherical vertex diagnostic.');
    assert(evt.tir_flag(1), ...
        'Event-level spherical vertex diagnostic should flag TIR.');
    assert(isnan(evt.u_out_exact_vertex(1)), ...
        'TIR event should not fabricate exact output.');
    assert(isnan(evt.delta_u_vertex_scalar(1)), ...
        'TIR event should not fabricate vertex delta.');
    assert(evt.warning_level(1) == "severe", ...
        'TIR event should force severe warning.');
end


function test_nonfinite_snell_argument_local()
    diag = nparaxial_surface_vertex_scalar_validity_yu( ...
        0, Inf, 1, 1.5, 10, []);

    assert(isnan(diag.u_out_exact_vertex), ...
        'Nonfinite Snell argument should not produce exact output.');
    assert(isnan(diag.delta_u_vertex_scalar), ...
        'Nonfinite Snell argument should not produce vertex delta.');
    assert(diag.warning_level == "severe", ...
        'Nonfinite Snell argument should force severe warning.');
    assert(contains(diag.note, "Snell argument is nonfinite"), ...
        'Note should mention nonfinite Snell argument.');
end


function test_worst_surface_vertex_delta_summary_local()
    p = prescription_local(["S1"; "S2"], [1; 2], ...
        ["surface"; "surface"], [10; 20], [Inf; Inf], ...
        [Inf; Inf], [50; -30], [1; 1.5], [1.5; 1]);
    rays = ray_table_local("two_surfaces", 0, 5, 0.1);
    validity = nparaxial_paraxial_validity_yu( ...
        bundle_set_local(rays, p, 20), p);
    evt = validity.event_table;
    surfaceRows = evt(evt.diagnostic_type == "spherical_vertex_scalar", :);

    assert(height(surfaceRows) == 2, ...
        'Summary test should have two spherical vertex event rows.');
    expected = signed_max_abs_local(surfaceRows.delta_u_vertex_scalar);
    assert_close_local( ...
        validity.summary_table.worst_surface_vertex_delta_u(1), ...
        expected, ...
        'Summary should report signed max-absolute surface vertex delta.');
end


function value = signed_max_abs_local(values)
    values = double(values(:));
    values = values(isfinite(values));
    assert(~isempty(values), ...
        'Expected at least one finite surface vertex delta.');
    [~, idx] = max(abs(values));
    value = values(idx);
end


function bundleSet = bundle_set_local(rays, prescription, zFinal)
    bundleSet = struct();
    bundleSet.field_index = 1;
    bundleSet.y_obj = rays.y0(1);
    bundleSet.rays = rays;
    bundleSet.bundle = nparaxial_trace_bundle_yu(rays, prescription, zFinal);
end


function rays = ray_table_local(name, z0, y0, u0)
    rays = table;
    rays.name = string(name(:));
    rays.z0 = double(z0(:));
    rays.y0 = double(y0(:));
    rays.u0 = double(u0(:));
    rays.sampling_mode = repmat("test", height(rays), 1);
end


function p = prescription_local( ...
    elementId, eventOrder, typeName, z, aperture, f, R, nBefore, nAfter)

    n = numel(string(elementId));
    p = table;
    p.element_id = string(elementId(:));
    p.event_order = expand_double_local(eventOrder, n);
    p.type = string(typeName(:));
    p.z = expand_double_local(z, n);
    p.aperture_radius = expand_double_local(aperture, n);
    p.focal_length = expand_double_local(f, n);
    p.radius_R = expand_double_local(R, n);
    p.n_before = expand_double_local(nBefore, n);
    p.n_after = expand_double_local(nAfter, n);
    p.enabled = true(n, 1);
    p = nparaxial_validate_prescription_yu(p);
end


function values = expand_double_local(values, n)
    values = double(values(:));
    if isscalar(values) && n > 1
        values = repmat(values, n, 1);
    end
end


function assert_close_local(actual, expected, message)
    assert(abs(actual - expected) < 1e-12, message);
end
