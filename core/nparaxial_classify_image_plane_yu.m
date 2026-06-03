function img = nparaxial_classify_image_plane_yu(M, z_ref, tol)
%NPARAXIAL_CLASSIFY_IMAGE_PLANE_YU Classify first-order image plane.
%
% For M = [A B; C D] at z_ref, an additional translation x gives
% B_total = B + x*D. The image condition is B_total = 0.

    if nargin < 3 || isempty(tol)
        tol = 1e-12;
    end
    if ~isnumeric(M) || ~isequal(size(M), [2 2]) || any(~isfinite(M(:)))
        error('M must be a finite 2-by-2 numeric matrix.');
    end
    if ~isscalar(z_ref) || ~isfinite(z_ref)
        error('z_ref must be a finite scalar.');
    end
    if ~isscalar(tol) || ~isfinite(tol) || tol <= 0
        error('tol must be a positive finite scalar.');
    end

    B = M(1, 2);
    D = M(2, 2);

    img = struct();
    img.type = "image at infinity / no finite image";
    img.is_finite = false;
    img.is_real = false;
    img.is_virtual = false;
    img.is_at_infinity = true;
    img.x_from_reference = Inf;
    img.z_image = Inf;
    img.message = "B + xD cannot be solved because D is approximately zero.";

    if abs(D) <= tol
        return
    end

    x = -B / D;
    zImage = z_ref + x;

    img.is_finite = isfinite(zImage);
    img.is_at_infinity = ~img.is_finite;
    img.x_from_reference = x;
    img.z_image = zImage;

    if ~img.is_finite
        img.message = "Image plane is not finite.";
        return
    end

    if x >= 0
        img.type = "finite real image";
        img.is_real = true;
        img.message = "Finite real image found by forward translation from the final reference plane.";
    else
        img.type = "finite virtual image";
        img.is_virtual = true;
        img.message = "Finite virtual image found by backward extension from the final reference plane.";
    end
end
