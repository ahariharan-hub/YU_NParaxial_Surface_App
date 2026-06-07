function results = demo_nparaxial_milestone2351_true_intersection_stabilization_yu()
%DEMO_NPARAXIAL_MILESTONE2351_TRUE_INTERSECTION_STABILIZATION_YU Stabilization checks.

    testFolder = fileparts(mfilename('fullpath'));
    rootFolder = fileparts(testFolder);
    addpath(rootFolder);
    addpath(fullfile(rootFolder, 'core'));

    numChecks = 0;

    test_tangent_ambiguous_root_local();
    numChecks = numChecks + 1;

    test_true_hit_diagnostic_does_not_propagate_local();
    numChecks = numChecks + 1;

    results = struct();
    results.case_name = "milestone2351_true_intersection_stabilization";
    results.num_checks = numChecks;
end


function test_tangent_ambiguous_root_local()
    R = 10;
    y0 = 5;
    tangentSlope = (R^2 - y0^2) / (2*R*y0);
    uIn = atan(tangentSlope);
    hit = nparaxial_surface_true_intersection_validity_yu( ...
        y0, uIn, 1, 1.5, R, []);

    assert(hit.surface_intersection_ambiguous_flag, ...
        'Tangent-like local intersection should be flagged ambiguous.');
    assert(hit.warning_level == "severe", ...
        'Ambiguous true-intersection root selection should force severe warning.');
    assert(contains(hit.note, "ambiguous") || contains(hit.note, "tangent"), ...
        'Ambiguous/tangent note should be visible to users.');
    if isfinite(hit.u_out_exact_hit)
        assert(hit.surface_intersection_ambiguous_flag && ...
            hit.warning_level == "severe", ...
            'Any exact result in an ambiguous case must remain clearly flagged.');
    end
end


function test_true_hit_diagnostic_does_not_propagate_local()
    p = prescription_local(["S1"; "S2"], [1; 2], ...
        ["surface"; "surface"], [10; 25], [Inf; Inf], ...
        [Inf; Inf], [40; -35], [1; 1.5], [1.5; 1]);
    rays = ray_table_local(["r1"; "r2"], [0; 0], [2; -1], [0.03; -0.02]);
    zFinal = 40;

    bundleBefore = nparaxial_trace_bundle_yu(rays, p, zFinal);
    snapshotsBefore = trace_snapshot_local(bundleBefore);
    imageBefore = nparaxial_solve_image_plane_yu(p, rays.z0(1));

    bundleSet = bundle_set_local(rays, p, zFinal);
    validity = nparaxial_paraxial_validity_yu(bundleSet, p);

    assert(any(validity.event_table.diagnostic_type == ...
        "spherical_true_intersection_local"), ...
        'Regression setup should exercise true-intersection event diagnostics.');
    assert(any(isfinite(validity.event_table.u_out_exact_hit)), ...
        'True-intersection diagnostic should compute finite exact-hit values.');

    bundleAfter = nparaxial_trace_bundle_yu(rays, p, zFinal);
    snapshotsAfter = trace_snapshot_local(bundleAfter);
    imageAfter = nparaxial_solve_image_plane_yu(p, rays.z0(1));

    assert_same_snapshot_local(snapshotsAfter, snapshotsBefore, ...
        'Validity diagnostics must not alter downstream paraxial trace states.');
    assert_close_local(imageAfter.z_img, imageBefore.z_img, ...
        'Validity diagnostics must not alter image-plane solution.');
    assert_close_local(imageAfter.m, imageBefore.m, ...
        'Validity diagnostics must not alter image-plane magnification.');
end


function snapshot = trace_snapshot_local(bundle)
    snapshot = struct();
    for k = 1:numel(bundle)
        res = bundle(k).res;
        snapshot(k).trc = res.trc; %#ok<AGROW>
        snapshot(k).yf = res.yf; %#ok<AGROW>
        snapshot(k).uf = res.uf; %#ok<AGROW>
        snapshot(k).z_hist = res.z_hist; %#ok<AGROW>
        snapshot(k).y_hist = res.y_hist; %#ok<AGROW>
        snapshot(k).u_hist = res.u_hist; %#ok<AGROW>
        snapshot(k).n_hist = res.n_hist; %#ok<AGROW>
        snapshot(k).blocked_at_index = res.blocked_at_index; %#ok<AGROW>
        snapshot(k).blocked_at_z = res.blocked_at_z; %#ok<AGROW>
        snapshot(k).blocked_y = res.blocked_y; %#ok<AGROW>
        snapshot(k).blocked_u = res.blocked_u; %#ok<AGROW>
        snapshot(k).blocked_aperture = res.blocked_aperture; %#ok<AGROW>
        snapshot(k).events = res.events; %#ok<AGROW>
    end
end


function assert_same_snapshot_local(actual, expected, message)
    assert(numel(actual) == numel(expected), message);
    for k = 1:numel(actual)
        assert(actual(k).trc == expected(k).trc, message);
        assert_close_nan_local(actual(k).yf, expected(k).yf, message);
        assert_close_nan_local(actual(k).uf, expected(k).uf, message);
        assert_vector_close_local(actual(k).z_hist, expected(k).z_hist, message);
        assert_vector_close_local(actual(k).y_hist, expected(k).y_hist, message);
        assert_vector_close_local(actual(k).u_hist, expected(k).u_hist, message);
        assert_vector_close_local(actual(k).n_hist, expected(k).n_hist, message);
        assert_close_nan_local(actual(k).blocked_at_index, ...
            expected(k).blocked_at_index, message);
        assert_close_nan_local(actual(k).blocked_at_z, ...
            expected(k).blocked_at_z, message);
        assert_close_nan_local(actual(k).blocked_y, expected(k).blocked_y, message);
        assert_close_nan_local(actual(k).blocked_u, expected(k).blocked_u, message);
        assert_close_nan_local(actual(k).blocked_aperture, ...
            expected(k).blocked_aperture, message);
        assert(isequaln(actual(k).events, expected(k).events), message);
    end
end


function assert_vector_close_local(actual, expected, message)
    actual = double(actual(:));
    expected = double(expected(:));
    assert(numel(actual) == numel(expected), message);
    for k = 1:numel(actual)
        assert_close_nan_local(actual(k), expected(k), message);
    end
end


function assert_close_nan_local(actual, expected, message)
    if isnan(actual) && isnan(expected)
        return
    end
    assert_close_local(actual, expected, message);
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
