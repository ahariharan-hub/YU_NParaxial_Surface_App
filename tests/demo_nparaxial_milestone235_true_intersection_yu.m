function results = demo_nparaxial_milestone235_true_intersection_yu()
%DEMO_NPARAXIAL_MILESTONE235_TRUE_INTERSECTION_YU Local hit diagnostics.

    testFolder = fileparts(mfilename('fullpath'));
    rootFolder = fileparts(testFolder);
    addpath(rootFolder);
    addpath(fullfile(rootFolder, 'core'));

    numChecks = 0;

    test_axial_on_vertex_local();
    numChecks = numChecks + 1;

    test_normal_incidence_sag_local();
    numChecks = numChecks + 1;

    test_small_angle_agreement_local();
    numChecks = numChecks + 1;

    test_sign_convention_local();
    numChecks = numChecks + 1;

    test_no_intersection_local();
    numChecks = numChecks + 1;

    test_tir_at_hit_local();
    numChecks = numChecks + 1;

    test_plane_surface_separation_local();
    numChecks = numChecks + 1;

    results = struct();
    results.case_name = "milestone235_true_intersection";
    results.num_checks = numChecks;
end


function test_axial_on_vertex_local()
    y0 = 0;
    uIn = 0;
    n1 = 1;
    n2 = 1.5;
    R = 50;
    uPara = surface_matrix_u_local(y0, uIn, n1, n2, R);
    vertex = nparaxial_surface_vertex_scalar_validity_yu( ...
        y0, uIn, n1, n2, R, uPara);
    hit = nparaxial_surface_true_intersection_validity_yu( ...
        y0, uIn, n1, n2, R, uPara, vertex);

    assert_close_local(hit.surface_intersection_s, 0, ...
        'Axial ray should hit at the vertex plane.');
    assert_close_local(hit.surface_intersection_y, 0, ...
        'Axial ray should hit at y = 0.');
    assert_close_local(hit.u_out_exact_hit, vertex.u_out_exact_vertex, ...
        'Axial true-hit diagnostic should equal vertex scalar diagnostic.');
end


function test_normal_incidence_sag_local()
    y0 = 5;
    uIn = 0;
    R = 100;
    expectedSag = R - sign(R)*sqrt(R^2 - y0^2);
    hit = nparaxial_surface_true_intersection_validity_yu( ...
        y0, uIn, 1, 1.5, R, []);

    assert_close_local(hit.surface_intersection_s, expectedSag, ...
        'Normal-incidence hit should equal the sag branch.');
    assert_close_local(hit.surface_intersection_y, y0, ...
        'Normal-incidence hit height should remain y0.');
end


function test_small_angle_agreement_local()
    y0 = 1e-4;
    uIn = 2e-4;
    n1 = 1;
    n2 = 1.5;
    R = 100;
    uPara = surface_matrix_u_local(y0, uIn, n1, n2, R);
    vertex = nparaxial_surface_vertex_scalar_validity_yu( ...
        y0, uIn, n1, n2, R, uPara);
    hit = nparaxial_surface_true_intersection_validity_yu( ...
        y0, uIn, n1, n2, R, uPara, vertex);

    assert(abs(hit.u_out_exact_hit - vertex.u_out_exact_vertex) < 1e-9, ...
        'Small-angle true-hit output should be close to vertex scalar output.');
    assert(abs(hit.u_out_exact_hit - uPara) < 1e-9, ...
        'Small-angle true-hit output should be close to paraxial matrix output.');
end


function test_sign_convention_local()
    y0 = 5;
    uIn = 0;
    n1 = 1;
    n2 = 1.5;
    hitPos = nparaxial_surface_true_intersection_validity_yu( ...
        y0, uIn, n1, n2, 100, []);
    hitNeg = nparaxial_surface_true_intersection_validity_yu( ...
        y0, uIn, n1, n2, -100, []);

    assert(hitPos.u_out_exact_hit < 0, ...
        'R > 0, y0 > 0, n1 < n2 should give negative true-hit output.');
    assert(hitNeg.u_out_exact_hit > 0, ...
        'R < 0, y0 > 0, n1 < n2 should reverse true-hit output sign.');
    assert(hitPos.surface_alpha_hit < 0 && hitNeg.surface_alpha_hit > 0, ...
        'True-hit normal convention must use alpha_hit = -asin(y_hit/R).');
end


function test_no_intersection_local()
    hit = nparaxial_surface_true_intersection_validity_yu( ...
        9, atan(1), 1, 1.5, 10, []);

    assert(hit.no_intersection_flag, ...
        'Missing the sphere should set no_intersection_flag.');
    assert(~hit.surface_intersection_exists, ...
        'Missing the sphere should not report an existing intersection.');
    assert(isnan(hit.u_out_exact_hit), ...
        'No-intersection case should not fabricate exact-hit output.');
    assert(hit.warning_level == "severe", ...
        'No-intersection case should force severe warning.');
end


function test_tir_at_hit_local()
    hit = nparaxial_surface_true_intersection_validity_yu( ...
        0, 1.0, 1.5, 1.0, 10, []);

    assert(hit.tir_hit_flag, ...
        'Large n1 > n2 incidence at hit should flag TIR.');
    assert(isnan(hit.u_out_exact_hit), ...
        'TIR should not fabricate exact-hit output.');
    assert(hit.warning_level == "severe", ...
        'TIR at hit should force severe warning.');
end


function test_plane_surface_separation_local()
    p = prescription_local("P1", 1, "surface", 10, ...
        Inf, Inf, Inf, 1, 1.5);
    rays = ray_table_local("plane", 0, 0, 0.2);
    validity = nparaxial_paraxial_validity_yu( ...
        bundle_set_local(rays, p, 10), p);
    evt = validity.event_table;

    assert(evt.diagnostic_type(1) == "plane_refraction", ...
        'R = Inf surface should remain a plane-refraction diagnostic.');
    assert(evt.diagnostic_type(1) ~= "spherical_true_intersection_local", ...
        'R = Inf surface must not use local true-intersection diagnostics.');
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


function assert_close_local(actual, expected, message)
    assert(abs(actual - expected) < 1e-12, message);
end
