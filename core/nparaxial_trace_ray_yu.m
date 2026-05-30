function res = nparaxial_trace_ray_yu(ray, prescription, z_final)
%NPARAXIAL_TRACE_RAY_YU Trace one y-u ray through all enabled elements.
%
% Ray convention:
%   ray = [z0, y0, u0]

    if ~isnumeric(ray) || numel(ray) ~= 3
        error('ray must be a numeric vector [z0, y0, u0].');
    end

    ray = double(ray(:).');
    if any(~isfinite(ray))
        error('ray values must be finite.');
    end

    if ~isscalar(z_final) || ~isfinite(z_final)
        error('z_final must be a finite scalar.');
    end

    z0 = ray(1);
    y0 = ray(2);
    u0 = ray(3);

    if z_final < z0
        error('Forward tracing requires z_final >= ray(1).');
    end

    elements = nparaxial_enabled_elements_yu(prescription, z0, z_final);

    z_curr = z0;
    v = [y0; u0];
    n_curr = nparaxial_medium_index_at_z_yu(prescription, z0, "before");

    z_hist = z0;
    y_hist = y0;
    u_hist = u0;
    n_hist = n_curr;
    seg_z = {};
    seg_y = {};
    seg_n = {};

    trc = true;
    blocked_at_index = NaN;
    blocked_element_id = "";
    blocked_at_z = NaN;
    blocked_y = NaN;
    blocked_u = NaN;
    blocked_aperture = NaN;

    events = table( ...
        zeros(0, 1), strings(0, 1), strings(0, 1), ...
        zeros(0, 1), zeros(0, 1), zeros(0, 1), zeros(0, 1), ...
        zeros(0, 1), zeros(0, 1), zeros(0, 1), zeros(0, 1), ...
        false(0, 1), zeros(0, 1), zeros(0, 1), ...
        'VariableNames', { ...
        'index', 'element_id', 'type', 'z', 'aperture_radius', ...
        'focal_length', 'radius_R', 'n_before', 'n_after', ...
        'y_before', 'u_before', 'passed_aperture', 'y_after', 'u_after'} );

    for k = 1:height(elements)
        element = elements(k, :);
        z_element = element.z(1);
        d = z_element - z_curr;

        if d < -1e-12
            error('Enabled element positions must be sorted in increasing z.');
        end

        % Translate to the element vertex plane before testing the aperture
        % or applying any optical event.
        v_before = [v(1) + d*v(2); v(2)];

        seg_z{end+1, 1} = [z_curr, z_element]; %#ok<AGROW>
        seg_y{end+1, 1} = [v(1), v_before(1)]; %#ok<AGROW>
        seg_n{end+1, 1} = n_curr; %#ok<AGROW>

        aperture = element.aperture_radius(1);
        % Aperture clipping is evaluated at the element plane before the
        % thin lens, surface, stop, or dummy event is applied.
        passed = isinf(aperture) || abs(v_before(1)) <= aperture + 1e-12;

        if ~passed
            trc = false;
            blocked_at_index = k;
            blocked_element_id = element.element_id(1);
            blocked_at_z = z_element;
            blocked_y = v_before(1);
            blocked_u = v_before(2);
            blocked_aperture = aperture;

            events(end+1, :) = { ...
                k, element.element_id(1), element.type(1), z_element, aperture, ...
                element.focal_length(1), element.radius_R(1), ...
                element.n_before(1), element.n_after(1), ...
                v_before(1), v_before(2), false, NaN, NaN};

            z_hist(end+1, 1) = z_element; %#ok<AGROW>
            y_hist(end+1, 1) = v_before(1); %#ok<AGROW>
            u_hist(end+1, 1) = v_before(2); %#ok<AGROW>
            n_hist(end+1, 1) = n_curr; %#ok<AGROW>

            v = v_before;
            z_curr = z_element;
            break
        end

        % Element event: surfaces update u and the medium index, thin lenses
        % update u without changing medium, and stops/dummies are identity.
        E = nparaxial_element_matrix_yu(element);
        v_after = E * v_before;
        n_after = n_curr;
        if element.type(1) == "surface"
            n_after = element.n_after(1);
        end

        events(end+1, :) = { ...
            k, element.element_id(1), element.type(1), z_element, aperture, ...
            element.focal_length(1), element.radius_R(1), ...
            element.n_before(1), element.n_after(1), ...
            v_before(1), v_before(2), true, v_after(1), v_after(2)};

        z_hist(end+1, 1) = z_element; %#ok<AGROW>
        y_hist(end+1, 1) = v_before(1); %#ok<AGROW>
        u_hist(end+1, 1) = v_after(2); %#ok<AGROW>
        n_hist(end+1, 1) = n_after; %#ok<AGROW>

        v = v_after;
        n_curr = n_after;
        z_curr = z_element;
    end

    if trc
        v_final = [v(1) + (z_final - z_curr)*v(2); v(2)];
        seg_z{end+1, 1} = [z_curr, z_final];
        seg_y{end+1, 1} = [v(1), v_final(1)];
        seg_n{end+1, 1} = n_curr;
        yf = v_final(1);
        uf = v_final(2);
    else
        yf = NaN;
        uf = NaN;
    end

    res = struct();
    res.trc = trc;
    res.z_hist = z_hist;
    res.y_hist = y_hist;
    res.u_hist = u_hist;
    res.n_hist = n_hist;
    res.seg_z = seg_z;
    res.seg_y = seg_y;
    res.seg_n = seg_n;
    res.events = events;
    res.z0 = z0;
    res.y0 = y0;
    res.u0 = u0;
    res.zf = z_final;
    res.yf = yf;
    res.uf = uf;
    res.z_last = z_curr;
    res.y_last = v(1);
    res.u_last = v(2);
    res.n_last = n_curr;
    res.blocked_at_index = blocked_at_index;
    res.blocked_element_id = blocked_element_id;
    res.blocked_at_z = blocked_at_z;
    res.blocked_y = blocked_y;
    res.blocked_u = blocked_u;
    res.blocked_aperture = blocked_aperture;
end
