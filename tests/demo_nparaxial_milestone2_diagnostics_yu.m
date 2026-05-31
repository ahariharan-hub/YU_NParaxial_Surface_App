function result = demo_nparaxial_milestone2_diagnostics_yu()
%DEMO_NPARAXIAL_MILESTONE2_DIAGNOSTICS_YU Validate first-order diagnostics.

    testFolder = fileparts(mfilename('fullpath'));
    rootFolder = fileparts(testFolder);
    addpath(fullfile(rootFolder, 'core'));

    test_single_thin_lens_cardinal_local();
    test_two_thin_lens_cardinal_local();
    test_two_surface_cardinal_local();
    test_plane_surface_afocal_local();
    test_stop_only_pupils_local();
    test_lens_before_stop_entrance_pupil_local();
    test_lens_after_stop_exit_pupil_local();
    test_chief_marginal_stop_coordinates_local();
    test_lagrange_invariant_local();
    test_same_z_event_ordering_local();
    test_powered_stop_exit_pupil_local();
    test_partial_matrix_ignores_disabled_rows_local();
    test_blocked_ray_invariant_invalidation_local();

    result = struct();
    result.case_name = "milestone2_diagnostics";
    result.num_checks = 13;
end


function test_single_thin_lens_cardinal_local()
    p = nparaxial_default_prescription_yu("single thin lens");
    zLens = p.z(1);
    f = p.focal_length(1);
    card = nparaxial_cardinal_points_yu(p, zLens, zLens);

    assert_close_local(card.z_H1, zLens, 'single thin lens z_H1');
    assert_close_local(card.z_H2, zLens, 'single thin lens z_H2');
    assert_close_local(card.f_prime, f, 'single thin lens f_prime');
    assert_close_local(card.z_F, zLens - f, 'single thin lens z_F');
    assert_close_local(card.z_Fp, zLens + f, 'single thin lens z_Fp');
end


function test_two_thin_lens_cardinal_local()
    p = nparaxial_default_prescription_yu("two thin lenses");
    events = nparaxial_event_sequence_yu(p);
    z1 = events.z(1);
    z2 = events.z(end);
    card = nparaxial_cardinal_points_yu(p, z1, z2);
    expected = direct_cardinal_local(p, z1, z2);

    assert_close_local(card.z_H1, expected.z_H1, 'two lens z_H1');
    assert_close_local(card.z_H2, expected.z_H2, 'two lens z_H2');
    assert_close_local(card.z_F, expected.z_F, 'two lens z_F');
    assert_close_local(card.z_Fp, expected.z_Fp, 'two lens z_Fp');
    assert_close_local(card.determinant, card.expected_determinant, ...
        'two lens determinant');

    f1 = p.focal_length(p.element_id == "L1");
    f2 = p.focal_length(p.element_id == "L2");
    zL1 = p.z(p.element_id == "L1");
    zL2 = p.z(p.element_id == "L2");
    d = zL2 - zL1;
    phiClosedForm = 1/f1 + 1/f2 - d/(f1*f2);
    assert_close_local(card.Phi, phiClosedForm, ...
        'two lens closed-form equivalent power');
end


function test_two_surface_cardinal_local()
    p = nparaxial_default_prescription_yu("two-surface thick lens");
    events = nparaxial_event_sequence_yu(p);
    card = nparaxial_cardinal_points_yu(p, events.z(1), events.z(end));
    expected = direct_cardinal_local(p, events.z(1), events.z(end));

    assert(card.is_finite_power, 'Two-surface thick lens should have finite power.');
    assert_close_local(card.determinant, card.expected_determinant, ...
        'two-surface determinant');
    assert_close_local(card.z_H1, expected.z_H1, 'two-surface z_H1');
    assert_close_local(card.z_H2, expected.z_H2, 'two-surface z_H2');
    assert_close_local(card.f_prime, expected.f_prime, 'two-surface f_prime');
end


function test_plane_surface_afocal_local()
    p = make_prescription_local( ...
        ["P1"], 1, ["surface"], 0, Inf, Inf, Inf, 1, 1.5);
    card = nparaxial_cardinal_points_yu(p, 0, 0);

    assert(~card.is_finite_power, ...
        'Plane refracting surface should be reported as zero-power.');
    assert_close_local(card.C, 0, 'plane surface C');
    assert_close_local(card.determinant, card.expected_determinant, ...
        'plane surface determinant');
end


function test_stop_only_pupils_local()
    p = make_prescription_local( ...
        ["STOP"], 1, ["stop"], 0, 10, Inf, Inf, 1, 1);
    pupil = nparaxial_pupil_diagnostics_yu(p, 0, 0, 1);

    assert_close_local(pupil.z_EP, 0, 'stop only z_EP');
    assert_close_local(pupil.r_EP, 10, 'stop only r_EP');
    assert_close_local(pupil.z_XP, 0, 'stop only z_XP');
    assert_close_local(pupil.r_XP, 10, 'stop only r_XP');
end


function test_lens_before_stop_entrance_pupil_local()
    p = make_prescription_local( ...
        ["L1"; "STOP"], [1; 2], ["thinlens"; "stop"], ...
        [0; 50], [Inf; 10], [100; Inf], [Inf; Inf], ...
        [1; 1], [1; 1]);
    pupil = nparaxial_pupil_diagnostics_yu(p, 0, 50, 2);

    assert_close_local(pupil.z_EP, 100, 'lens before stop z_EP');
    assert_close_local(pupil.r_EP, 20, 'lens before stop r_EP');
end


function test_lens_after_stop_exit_pupil_local()
    p = make_prescription_local( ...
        ["STOP"; "L1"], [1; 2], ["stop"; "thinlens"], ...
        [0; 50], [10; Inf], [Inf; 100], [Inf; Inf], ...
        [1; 1], [1; 1]);
    pupil = nparaxial_pupil_diagnostics_yu(p, 0, 50, 1);

    assert_close_local(pupil.z_XP, -50, 'lens after stop z_XP');
    assert_close_local(pupil.r_XP, 20, 'lens after stop r_XP');
end


function test_chief_marginal_stop_coordinates_local()
    p = make_prescription_local( ...
        ["STOP"], 1, ["stop"], 0, 10, Inf, Inf, 1, 1);
    diag = nparaxial_chief_marginal_rays_yu(p, -100, 0, 20, 1);
    stopRows = diag.event_table.element_id == "STOP";
    yStop = diag.event_table.y_before(stopRows);

    assert_close_local(yStop(1), 0, 'chief stop coordinate');
    assert_close_local(yStop(2), 10, 'upper marginal stop coordinate');
    assert_close_local(yStop(3), -10, 'lower marginal stop coordinate');
end


function test_lagrange_invariant_local()
    p = make_prescription_local( ...
        ["STOP"; "S1"; "S2"], [1; 2; 3], ...
        ["stop"; "surface"; "surface"], [0; 10; 20], ...
        [5; Inf; Inf], [Inf; Inf; Inf], [Inf; 40; -40], ...
        [1; 1; 1.5], [1; 1.5; 1]);
    diag = nparaxial_chief_marginal_rays_yu(p, -50, 0, 80, 1);
    inv = nparaxial_lagrange_invariant_yu(diag);

    assert(all(inv.summary.both_unblocked), ...
        'Invariant test rays should be unblocked.');
    assert(max(inv.summary.max_abs_H_delta) < 1e-10, ...
        'Canonical Lagrange invariant should be conserved.');
end


function test_same_z_event_ordering_local()
    pA = make_prescription_local( ...
        ["L1"; "S1"], [1; 2], ["thinlens"; "surface"], ...
        [0; 0], [Inf; Inf], [100; Inf], [Inf; 50], ...
        [1; 1], [1; 1.5]);
    pB = make_prescription_local( ...
        ["S1"; "L1"], [1; 2], ["surface"; "thinlens"], ...
        [0; 0], [Inf; Inf], [Inf; 100], [50; Inf], ...
        [1; 1.5], [1.5; 1.5]);

    cardA = nparaxial_cardinal_points_yu(pA, 0, 0);
    cardB = nparaxial_cardinal_points_yu(pB, 0, 0);
    assert(norm(cardA.M - cardB.M, 'fro') > 1e-6, ...
        'Same-z event_order should affect noncommuting cardinal matrices.');

    pPupilA = make_prescription_local( ...
        ["L1"; "STOP"], [1; 2], ["thinlens"; "stop"], ...
        [0; 0], [Inf; 10], [100; Inf], [Inf; Inf], ...
        [1; 1], [1; 1]);
    pPupilB = make_prescription_local( ...
        ["STOP"; "L1"], [1; 2], ["stop"; "thinlens"], ...
        [0; 0], [10; Inf], [Inf; 100], [Inf; Inf], ...
        [1; 1], [1; 1]);

    pupilA = nparaxial_pupil_diagnostics_yu(pPupilA, 0, 20, 2);
    pupilB = nparaxial_pupil_diagnostics_yu(pPupilB, 0, 20, 1);
    assert(ismember(1, pupilA.pre_event_indices), ...
        'Same-z pre-stop event should be included by event identity.');
    assert(ismember(2, pupilB.post_event_indices), ...
        'Same-z post-stop event should be included by event identity.');
end


function test_powered_stop_exit_pupil_local()
    p = make_prescription_local( ...
        ["L1"; "L2"], [1; 2], ["thinlens"; "thinlens"], ...
        [0; 50], [10; Inf], [100; 75], [Inf; Inf], ...
        [1; 1], [1; 1]);
    pupil = nparaxial_pupil_diagnostics_yu(p, 0, 50, 1);
    events = nparaxial_event_sequence_yu(p);
    expected = nparaxial_partial_system_matrix_yu( ...
        events, 0, 50);
    excluded = nparaxial_partial_system_matrix_yu(events(2, :), 0, 50);

    assert(ismember(1, pupil.post_event_indices), ...
        'Powered selected stop event must be included in exit-pupil path.');
    assert(norm(pupil.M_post - expected, 'fro') < 1e-12, ...
        'Powered stop exit-pupil M_post did not include selected event.');
    assert(norm(pupil.M_post - excluded, 'fro') > 1e-9, ...
        'Powered stop exit-pupil path should differ from excluded-event path.');
end


function test_partial_matrix_ignores_disabled_rows_local()
    p = make_prescription_local( ...
        ["L1"; "L_OFF"], [1; 2], ["thinlens"; "thinlens"], ...
        [0; 0], [Inf; Inf], [100; 50], [Inf; Inf], ...
        [1; 1], [1; 1]);
    p.enabled(2) = false;

    M = nparaxial_partial_system_matrix_yu(p, 0, 0);
    expected = [1, 0; -1/100, 1];
    assert(norm(M - expected, 'fro') < 1e-12, ...
        'Partial matrix helper should ignore disabled rows.');
end


function test_blocked_ray_invariant_invalidation_local()
    p = make_prescription_local( ...
        ["STOP1"; "STOP2"], [1; 2], ["stop"; "stop"], ...
        [0; 10], [10; 1], [Inf; Inf], [Inf; Inf], ...
        [1; 1], [1; 1]);
    diag = nparaxial_chief_marginal_rays_yu(p, -100, 0, 20, 1);
    inv = nparaxial_lagrange_invariant_yu(diag);

    assert(any(~inv.table.invariant_valid), ...
        'Blocked rays should produce invalid invariant rows.');
    assert(any(isnan(inv.table.canonical_H(~inv.table.invariant_valid))), ...
        'Invalid invariant rows should have NaN canonical_H.');
    assert(all(~inv.summary.both_unblocked), ...
        'Summary should flag blocked chief/marginal pairs as not both unblocked.');
end


function expected = direct_cardinal_local(p, z1, z2)
    M = nparaxial_system_matrix_yu(p, z1, z2);
    A = M(1, 1);
    C = M(2, 1);
    D = M(2, 2);
    n1 = nparaxial_medium_index_at_z_yu(p, z1, "before");
    n2 = nparaxial_medium_index_at_z_yu(p, z2, "after");
    Delta = n1/n2;

    expected = struct();
    expected.f_prime = -1/C;
    expected.z_H1 = z1 + (D - Delta)/C;
    expected.z_H2 = z2 + (1 - A)/C;
    expected.z_F = z1 + D/C;
    expected.z_Fp = z2 - A/C;
end


function p = make_prescription_local( ...
    elementId, eventOrder, typeName, z, aperture, focalLength, radiusR, ...
    nBefore, nAfter)

    p = table;
    p.element_id = string(elementId(:));
    p.event_order = double(eventOrder(:));
    p.type = string(typeName(:));
    p.z = double(z(:));
    p.aperture_radius = double(aperture(:));
    p.focal_length = double(focalLength(:));
    p.radius_R = double(radiusR(:));
    p.n_before = double(nBefore(:));
    p.n_after = double(nAfter(:));
    p.enabled = true(height(p), 1);
    p = nparaxial_validate_prescription_yu(p);
end


function assert_close_local(actual, expected, label)
    tol = 1e-9 * max(1, abs(expected));
    assert(abs(actual - expected) <= tol, ...
        '%s mismatch: actual %.12g, expected %.12g.', ...
        label, actual, expected);
end
