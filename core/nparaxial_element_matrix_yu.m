function E = nparaxial_element_matrix_yu(element)
%NPARAXIAL_ELEMENT_MATRIX_YU First-order y-u matrix for one element.
%
% Supported types:
%   thinlens: L(f) = [1 0; -1/f 1]
%   surface:  S = [1 0; (n1-n2)/(n2*R) n1/n2]
%   stop:     identity
%   dummy:    identity

    element = nparaxial_validate_prescription_yu(element);
    if height(element) ~= 1
        error('nparaxial_element_matrix_yu expects exactly one table row.');
    end

    switch element.type(1)
        case "thinlens"
            f = element.focal_length(1);
            E = [1, 0; -1/f, 1];

        case "surface"
            n1 = element.n_before(1);
            n2 = element.n_after(1);
            R = element.radius_R(1);
            if isinf(R)
                curvatureTerm = 0;
            else
                curvatureTerm = (n1 - n2)/(n2*R);
            end
            E = [1, 0; curvatureTerm, n1/n2];

        case {"stop", "dummy"}
            E = eye(2);

        otherwise
            error('Unsupported element type "%s".', element.type(1));
    end
end
