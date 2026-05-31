function card = nparaxial_cardinal_points_yu(prescription, z1, z2, tol)
%NPARAXIAL_CARDINAL_POINTS_YU First-order cardinal/Gaussian diagnostics.

    if nargin < 4 || isempty(tol)
        tol = 1e-12;
    end

    events = nparaxial_event_sequence_yu(prescription);
    if isempty(events)
        error('At least one enabled event is required.');
    end
    if nargin < 2 || isempty(z1)
        z1 = events.z(1);
    end
    if nargin < 3 || isempty(z2)
        z2 = events.z(end);
    end
    if z2 < z1
        error('z2 must be greater than or equal to z1.');
    end

    M = nparaxial_system_matrix_yu(prescription, z1, z2);
    A = M(1, 1);
    B = M(1, 2);
    C = M(2, 1);
    D = M(2, 2);

    n1 = nparaxial_medium_index_at_z_yu(prescription, z1, "before");
    n2 = nparaxial_medium_index_at_z_yu(prescription, z2, "after");
    Delta = n1 / n2;
    Phi = -n2 * C;
    determinant = A*D - B*C;
    detError = determinant - Delta;

    card = struct();
    card.z1 = z1;
    card.z2 = z2;
    card.M = M;
    card.A = A;
    card.B = B;
    card.C = C;
    card.D = D;
    card.n1 = n1;
    card.n2 = n2;
    card.Delta = Delta;
    card.Phi = Phi;
    card.determinant = determinant;
    card.expected_determinant = Delta;
    card.determinant_error = detError;
    card.is_finite_power = abs(C) > tol;
    card.classification = "finite_power";

    card.f_prime = NaN;
    card.f = NaN;
    card.z_H1 = NaN;
    card.z_H2 = NaN;
    card.z_F = NaN;
    card.z_Fp = NaN;
    card.FFD = NaN;
    card.BFD = NaN;
    card.z_N1 = NaN;
    card.z_N2 = NaN;

    if card.is_finite_power
        card.f_prime = -1 / C;
        card.f = Delta / C;
        card.z_H1 = z1 + (D - Delta) / C;
        card.z_H2 = z2 + (1 - A) / C;
        card.z_F = z1 + D / C;
        card.z_Fp = z2 - A / C;
        card.FFD = D / C;
        card.BFD = -A / C;
        card.z_N1 = z1 + (D - 1) / C;
        card.z_N2 = z2 + (Delta - A) / C;
    else
        card.classification = "afocal_or_zero_power";
    end

    quantity = [
        "z1"; "z2"; "n1"; "n2"; "A"; "B"; "C"; "D"; ...
        "determinant"; "expected_determinant"; "determinant_error"; ...
        "Delta"; "Phi"; "f_prime"; "f"; "z_H1"; "z_H2"; ...
        "z_F"; "z_Fp"; "FFD"; "BFD"; "z_N1"; "z_N2"
    ];
    value = [
        card.z1; card.z2; card.n1; card.n2; card.A; card.B; card.C; card.D; ...
        card.determinant; card.expected_determinant; card.determinant_error; ...
        card.Delta; card.Phi; card.f_prime; card.f; card.z_H1; card.z_H2; ...
        card.z_F; card.z_Fp; card.FFD; card.BFD; card.z_N1; card.z_N2
    ];
    card.table = table(quantity, value);
end
