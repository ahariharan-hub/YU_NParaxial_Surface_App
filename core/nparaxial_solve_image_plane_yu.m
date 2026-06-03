function img = nparaxial_solve_image_plane_yu(prescription, z_obj, tol)
%NPARAXIAL_SOLVE_IMAGE_PLANE_YU Solve finite image plane by B + x*D = 0.

    if nargin < 3 || isempty(tol)
        tol = 1e-12;
    end
    if ~isscalar(z_obj) || ~isfinite(z_obj)
        error('z_obj must be a finite scalar.');
    end
    if ~isscalar(tol) || ~isfinite(tol) || tol <= 0
        error('tol must be a positive finite scalar.');
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
    img.isReal = false;
    img.isVirtual = false;
    img.isAtInfinity = true;
    img.is_finite = false;
    img.is_real = false;
    img.is_virtual = false;
    img.is_at_infinity = true;
    img.type = "image at infinity / no finite image";
    img.image_type = img.type;
    img.x_after_ref = Inf;
    img.x_from_reference = Inf;
    img.z_img = Inf;
    img.z_image = Inf;
    img.trace_z_final = z_ref;
    img.M_img = NaN(2, 2);
    img.A_img = NaN;
    img.B_img = NaN;
    img.C_img = NaN;
    img.D_img = NaN;
    img.m = NaN;
    img.B_residual = NaN;

    cls = nparaxial_classify_image_plane_yu(M_ref, z_ref, tol);
    img.type = cls.type;
    img.image_type = cls.type;
    img.is_finite = cls.is_finite;
    img.is_real = cls.is_real;
    img.is_virtual = cls.is_virtual;
    img.is_at_infinity = cls.is_at_infinity;
    img.isFinite = cls.is_finite;
    img.isReal = cls.is_real;
    img.isVirtual = cls.is_virtual;
    img.isAtInfinity = cls.is_at_infinity;
    img.x_after_ref = cls.x_from_reference;
    img.x_from_reference = cls.x_from_reference;
    img.z_img = cls.z_image;
    img.z_image = cls.z_image;
    img.note = char(cls.message);
    img.message = cls.message;

    if ~img.is_finite
        return
    end

    T = [1, img.x_after_ref; 0, 1];
    M_img = T * M_ref;

    img.M_img = M_img;
    img.A_img = M_img(1, 1);
    img.B_img = M_img(1, 2);
    img.C_img = M_img(2, 1);
    img.D_img = M_img(2, 2);
    img.m = M_img(1, 1);
    img.B_residual = M_img(1, 2);

    if img.is_real
        img.trace_z_final = img.z_img;
    else
        img.trace_z_final = img.z_ref;
    end
end
