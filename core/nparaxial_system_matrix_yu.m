function M = nparaxial_system_matrix_yu(prescription, z_in, z_out)
%NPARAXIAL_SYSTEM_MATRIX_YU Build ABCD matrix for an N-element y-u system.
%
% State convention:
%   r = [y; u]

    if ~isscalar(z_in) || ~isscalar(z_out) || ...
            ~isfinite(z_in) || ~isfinite(z_out)
        error('z_in and z_out must be finite scalar values.');
    end

    if z_out < z_in
        error('Forward propagation requires z_out >= z_in.');
    end

    elements = nparaxial_enabled_elements_yu(prescription, z_in, z_out);

    M = eye(2);
    z_curr = z_in;

    for k = 1:height(elements)
        z_element = elements.z(k);
        d = z_element - z_curr;
        if d < -1e-12
            error('Enabled elements must be sorted in increasing z.');
        end

        % Matrix order follows the physical ray path. The ray first
        % translates from the previous plane to this element plane, then the
        % element event is applied there: r_out = E*T*r_in.
        T = [1, d; 0, 1];
        M = T * M;

        % Stop and dummy elements use identity matrices. Thin lenses change
        % slope in the same medium. Refracting surfaces change slope and
        % encode the n_before -> n_after transition.
        E = nparaxial_element_matrix_yu(elements(k, :));
        M = E * M;

        z_curr = z_element;
    end

    % Final translation carries the state from the last included element
    % plane to the requested output plane.
    T = [1, z_out - z_curr; 0, 1];
    M = T * M;
end
