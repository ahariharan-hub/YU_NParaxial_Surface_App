function img = nparaxial_solve_image_plane_yu(prescription, z_obj)
%NPARAXIAL_SOLVE_IMAGE_PLANE_YU Solve finite image plane by B + x*D = 0.

    if ~isscalar(z_obj) || ~isfinite(z_obj)
        error('z_obj must be a finite scalar.');
    end

    elements = nparaxial_enabled_elements_yu(prescription);
    if isempty(elements)
        error('At least one enabled element is required.');
    end

    z_ref = max(elements.z);
    if z_ref <= z_obj
        error('The final enabled element must be after the object plane.');
    end

    M_ref = nparaxial_system_matrix_yu(prescription, z_obj, z_ref);
    A = M_ref(1, 1);
    B = M_ref(1, 2);
    C = M_ref(2, 1);
    D = M_ref(2, 2);

    img = struct();
    img.z_obj = z_obj;
    img.z_ref = z_ref;
    img.M_ref = M_ref;
    img.A_ref = A;
    img.B_ref = B;
    img.C_ref = C;
    img.D_ref = D;
    img.isFinite = false;
    img.x_after_ref = Inf;
    img.z_img = Inf;
    img.M_img = NaN(2, 2);
    img.A_img = NaN;
    img.B_img = NaN;
    img.C_img = NaN;
    img.D_img = NaN;
    img.m = NaN;
    img.B_residual = NaN;

    if abs(D) < 1e-12
        img.note = 'No finite image plane found because D is approximately zero.';
        return
    end

    x = -B / D;
    z_img = z_ref + x;

    T = [1, x; 0, 1];
    M_img = T * M_ref;

    img.x_after_ref = x;
    img.z_img = z_img;
    img.M_img = M_img;
    img.A_img = M_img(1, 1);
    img.B_img = M_img(1, 2);
    img.C_img = M_img(2, 1);
    img.D_img = M_img(2, 2);
    img.m = M_img(1, 1);
    img.B_residual = M_img(1, 2);
    img.isFinite = isfinite(z_img);

    if img.isFinite
        img.note = 'Finite first-order image plane found.';
    else
        img.note = 'Image plane is not finite.';
    end
end
