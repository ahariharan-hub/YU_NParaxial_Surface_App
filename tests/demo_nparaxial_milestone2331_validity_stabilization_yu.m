function results = demo_nparaxial_milestone2331_validity_stabilization_yu()
%DEMO_NPARAXIAL_MILESTONE2331_VALIDITY_STABILIZATION_YU Stabilization checks.

    testFolder = fileparts(mfilename('fullpath'));
    rootFolder = fileparts(testFolder);
    addpath(rootFolder);
    addpath(fullfile(rootFolder, 'core'));

    numChecks = 0;

    test_plane_surface_event_path_local();
    numChecks = numChecks + 1;

    test_combined_report_validity_text_local();
    numChecks = numChecks + 1;

    test_zero_length_segment_handling_local();
    numChecks = numChecks + 1;

    test_docs_no_stale_deferred_wording_local(rootFolder);
    numChecks = numChecks + 1;

    results = struct();
    results.case_name = "milestone2331_validity_stabilization";
    results.num_checks = numChecks;
end


function test_plane_surface_event_path_local()
    n1 = 1;
    n2 = 1.5;
    uIn = 0.2;
    p = prescription_local("P1", 1, "surface", 10, ...
        Inf, Inf, Inf, n1, n2);
    rays = ray_table_local("plane_surface", 0, 0, uIn);
    validity = nparaxial_paraxial_validity_yu( ...
        bundle_set_local(rays, p, 10), p);

    evt = validity.event_table;
    assert(height(evt) == 1, ...
        'Plane-surface test should produce one event row.');
    assert(evt.diagnostic_type(1) == "plane_refraction", ...
        'R = Inf surface with n_before ~= n_after should use plane refraction.');

    expectedDelta = asin((n1/n2)*sin(uIn)) - (n1/n2)*uIn;
    assert_close_local(evt.delta_u(1), expectedDelta, ...
        'Plane-surface event delta_u mismatch.');

    helper = nparaxial_plane_refraction_validity_yu(n1, n2, uIn);
    assert_close_local(helper.snell_argument_clamped, ...
        (n1/n2)*sin(uIn), ...
        'Plane-refraction helper should expose unclipped valid Snell argument.');
end


function test_combined_report_validity_text_local()
    p = prescription_local(["L1"; "STOP"], [1; 2], ...
        ["thinlens"; "stop"], [10; 20], [Inf; 5], [50; Inf], ...
        [Inf; Inf], [1; 1], [1; 1]);
    rays = ray_table_local("report_ray", 0, 0, 0.03);
    bundleSet = bundle_set_local(rays, p, 30);
    diagnostics = nparaxial_field_diagnostics_yu(p, 0, 30, 0);
    diagnostics.paraxial_validity = ...
        nparaxial_paraxial_validity_yu(bundleSet, p);
    diagnostics.paraxial_validity_error = "";

    matrixTable = matrix_table_local(p, 0, 30);
    img = image_struct_local(0, 20, 30);
    lines = nparaxial_combined_report_yu( ...
        p, matrixTable, img, diagnostics, "stabilization report");
    text = join(string(lines), newline);

    assert(contains(text, "Paraxial validity diagnostics"), ...
        'Combined report should include a paraxial-validity section.');
    assert(contains(text, "This is not exact ray tracing"), ...
        'Combined report should state that validity diagnostics are not exact tracing.');
    assert(contains(text, ...
        "Milestone 2.3.4 includes vertex-plane scalar validity"), ...
        'Combined report should state vertex-plane spherical validity is implemented.');
    assert(contains(text, ...
        "Milestone 2.3.5 includes local true-intersection diagnostics"), ...
        'Combined report should state local true-intersection diagnostics are implemented.');
    assert(contains(text, ...
        "Exact hit and exact output angle are not propagated downstream"), ...
        'Combined report should state exact-hit results are not propagated.');
end


function test_zero_length_segment_handling_local()
    p = prescription_local(["D1"; "D2"], [1; 2], ...
        ["dummy"; "dummy"], [10; 10], [Inf; Inf], [Inf; Inf], ...
        [Inf; Inf], [1; 1], [1; 1]);
    rays = ray_table_local("same_plane", 0, 0, 0.3);
    validity = nparaxial_paraxial_validity_yu( ...
        bundle_set_local(rays, p, 10), p);

    seg = validity.segment_table;
    evt = validity.event_table;
    assert(all(ismember(["segment_kind", "is_zero_length"], ...
        string(seg.Properties.VariableNames))), ...
        'Segment table should label zero-length rows explicitly.');

    zeroRows = seg(seg.is_zero_length, :);
    assert(height(zeroRows) >= 1, ...
        'Same-z/final-at-event trace should include zero-length segment rows.');
    assert(all(abs(zeroRows.delta_y_translation) < 1e-14), ...
        'Zero-length rows should not carry a translation penalty.');
    assert(any(zeroRows.segment_kind == "same_plane_angle_sample") || ...
        any(zeroRows.segment_kind == "zero_length_final"), ...
        'Zero-length rows should be classified as angle samples/final rows.');

    translationRows = seg(seg.segment_kind == "translation", :);
    expectedSevere = sum(translationRows.warning_level == "severe") + ...
        sum(evt.warning_level == "severe");
    allRowsSevere = sum(seg.warning_level == "severe") + ...
        sum(evt.warning_level == "severe");

    assert(validity.summary_table.severe_count(1) == expectedSevere, ...
        'Zero-length segment warnings should not inflate summary counts.');
    assert(allRowsSevere > expectedSevere, ...
        'Test case should contain severe zero-length rows excluded from counts.');
    assert(abs(validity.summary_table.worst_translation_delta_y(1) - ...
        translationRows.delta_y_translation(1)) < 1e-14, ...
        'Worst translation penalty should come from nonzero translations only.');
end


function test_docs_no_stale_deferred_wording_local(rootFolder)
    readmeText = string(fileread(fullfile(rootFolder, 'README.md')));
    appText = string(fileread(fullfile(rootFolder, ...
        'YU_NParaxialSurface_App_V1.m')));
    staleTokens = [
        "Paraxial-validity quantities such as"
        "paraxial-validity diagnostics are deferred"
        "Paraxial-validity diagnostics are deferred"
        "deferred to the next diagnostics milestone"
        "No paraxial-validity diagnostics"
        ];

    for k = 1:numel(staleTokens)
        assert(~contains(readmeText, staleTokens(k)), ...
            'README contains stale paraxial-validity wording: %s', ...
            staleTokens(k));
        assert(~contains(appText, staleTokens(k)), ...
            'App help contains stale paraxial-validity wording: %s', ...
            staleTokens(k));
    end

    assert(contains(readmeText, ...
        "Milestones 2.3.3-2.3.5 include propagation penalty"), ...
        'README should document the implemented 2.3.3 validity diagnostics.');
    assert(contains(appText, ...
        "Milestones 2.3.3-2.3.5 include propagation penalty"), ...
        'App help should document the implemented 2.3.3 validity diagnostics.');
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


function T = matrix_table_local(p, zObj, zImg)
    M = nparaxial_system_matrix_yu(p, zObj, zImg);
    T = table;
    T.quantity = ["A"; "B"; "C"; "D"];
    T.value = [M(1, 1); M(1, 2); M(2, 1); M(2, 2)];
end


function img = image_struct_local(zObj, zRef, zImg)
    img = struct();
    img.z_obj = zObj;
    img.z_ref = zRef;
    img.z_img = zImg;
    img.x_after_ref = zImg - zRef;
    img.m = NaN;
    img.B_residual = NaN;
end


function assert_close_local(actual, expected, message)
    assert(abs(actual - expected) < 1e-12, message);
end
