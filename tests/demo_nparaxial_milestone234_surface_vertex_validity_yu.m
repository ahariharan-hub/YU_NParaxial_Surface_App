function results = demo_nparaxial_milestone234_surface_vertex_validity_yu()
%DEMO_NPARAXIAL_MILESTONE234_SURFACE_VERTEX_VALIDITY_YU Surface diagnostics.

    testFolder = fileparts(mfilename('fullpath'));
    rootFolder = fileparts(testFolder);
    addpath(rootFolder);
    addpath(fullfile(rootFolder, 'core'));

    numChecks = 0;

    test_small_angle_reduction_local();
    numChecks = numChecks + 1;

    test_positive_radius_sign_local();
    numChecks = numChecks + 1;

    test_negative_radius_sign_local();
    numChecks = numChecks + 1;

    test_invalid_surface_normal_local();
    numChecks = numChecks + 1;

    test_surface_tir_local();
    numChecks = numChecks + 1;

    test_plane_surface_stays_plane_refraction_local();
    numChecks = numChecks + 1;

    results = struct();
    results.case_name = "milestone234_surface_vertex_validity";
    results.num_checks = numChecks;
end


function test_small_angle_reduction_local()
    y = 1e-4;
    uIn = 2e-4;
    n1 = 1;
    n2 = 1.5;
    R = 100;
    uPara = surface_matrix_u_local(y, uIn, n1, n2, R);
    diag = nparaxial_surface_vertex_scalar_validity_yu( ...
        y, uIn, n1, n2, R, uPara);
    assert(abs(diag.u_out_exact_vertex - uPara) < 1e-12, ...
        'Small-angle vertex scalar result should approach matrix output.');
    assert(abs(diag.delta_u_vertex_scalar) < 1e-12, ...
        'Small-angle vertex scalar delta should be tiny.');
end


function test_positive_radius_sign_local()
    y = 5;
    uIn = 0;
    n1 = 1;
    n2 = 1.5;
    R = 100;
    uPara = surface_matrix_u_local(y, uIn, n1, n2, R);
    diag = nparaxial_surface_vertex_scalar_validity_yu( ...
        y, uIn, n1, n2, R, uPara);
    assert(uPara < 0, ...
        'R > 0, y > 0, n1 < n2 should give negative matrix slope.');
    assert(diag.u_out_exact_vertex < 0, ...
        'Vertex scalar diagnostic should match the negative slope sign.');
    assert(diag.surface_alpha_vertex < 0, ...
        'Required convention alpha = -asin(y/R) should be negative here.');
end


function test_negative_radius_sign_local()
    y = 5;
    uIn = 0;
    n1 = 1;
    n2 = 1.5;
    R = -100;
    uPara = surface_matrix_u_local(y, uIn, n1, n2, R);
    diag = nparaxial_surface_vertex_scalar_validity_yu( ...
        y, uIn, n1, n2, R, uPara);
    assert(uPara > 0, ...
        'R < 0, y > 0, n1 < n2 should reverse matrix slope sign.');
    assert(diag.u_out_exact_vertex > 0, ...
        'Vertex scalar diagnostic should match the positive slope sign.');
    assert(diag.surface_alpha_vertex > 0, ...
        'Required convention alpha = -asin(y/R) should be positive here.');
end


function test_invalid_surface_normal_local()
    diag = nparaxial_surface_vertex_scalar_validity_yu( ...
        2, 0, 1, 1.5, 1, []);
    assert(diag.invalid_surface_normal_flag, ...
        'abs(y/R) > 1 should flag an invalid vertex-plane normal.');
    assert(isnan(diag.u_out_exact_vertex), ...
        'Invalid surface normal should not fabricate exact output slope.');
    assert(isnan(diag.delta_u_vertex_scalar), ...
        'Invalid surface normal should not fabricate scalar delta.');
    assert(diag.warning_level == "severe", ...
        'Invalid surface normal should force severe warning.');
end


function test_surface_tir_local()
    diag = nparaxial_surface_vertex_scalar_validity_yu( ...
        0, 1.0, 1.5, 1.0, 10, []);
    assert(diag.tir_flag, ...
        'Large n1 > n2 incidence should flag scalar TIR.');
    assert(isnan(diag.u_out_exact_vertex), ...
        'TIR should not fabricate exact vertex scalar output.');
    assert(isnan(diag.delta_u_vertex_scalar), ...
        'TIR should not fabricate scalar delta.');
    assert(diag.warning_level == "severe", ...
        'TIR should force severe warning.');
end


function test_plane_surface_stays_plane_refraction_local()
    p = prescription_local("P1", 1, "surface", 10, ...
        Inf, Inf, Inf, 1, 1.5);
    rays = ray_table_local("plane", 0, 0, 0.2);
    validity = nparaxial_paraxial_validity_yu( ...
        bundle_set_local(rays, p, 10), p);
    evt = validity.event_table;
    assert(evt.diagnostic_type(1) == "plane_refraction", ...
        'R = Inf surface should remain a plane-refraction diagnostic.');
    assert(evt.diagnostic_type(1) ~= "spherical_vertex_scalar", ...
        'R = Inf surface must not use spherical vertex diagnostics.');
end


function uOut = surface_matrix_u_local(y, uIn, n1, n2, R)
    uOut = (n1/n2)*uIn + ((n1 - n2)/(n2*R))*y;
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
