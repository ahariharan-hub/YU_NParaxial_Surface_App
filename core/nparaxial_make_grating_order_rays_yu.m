function [rays, info] = nparaxial_make_grating_order_rays_yu( ...
    z_obj, y_obj, wavelength_um, period_um, orders, ...
    incident_angle_deg, n_in, n_out)
%NPARAXIAL_MAKE_GRATING_ORDER_RAYS_YU Build object-plane grating rays.
%
% The grating is a source/ray-launch condition, not an ABCD element.
% Diffraction orders are computed from
%
%   n_out sin(theta_m) = n_in sin(theta_i) + m lambda / period
%
% and propagating orders are returned as a ray table accepted by
% nparaxial_trace_bundle_yu.

    if nargin < 6 || isempty(incident_angle_deg)
        incident_angle_deg = 0;
    end
    if nargin < 7 || isempty(n_in)
        n_in = 1;
    end
    if nargin < 8 || isempty(n_out)
        n_out = n_in;
    end

    validate_scalar_finite_local(z_obj, 'z_obj');
    validate_scalar_finite_local(y_obj, 'y_obj');
    validate_scalar_positive_local(wavelength_um, 'wavelength_um');
    validate_scalar_positive_local(period_um, 'period_um');
    validate_scalar_finite_local(incident_angle_deg, 'incident_angle_deg');
    validate_scalar_positive_local(n_in, 'n_in');
    validate_scalar_positive_local(n_out, 'n_out');

    if isempty(orders) || ~isnumeric(orders)
        error('orders must be a nonempty numeric vector.');
    end
    orders = double(orders(:));
    if any(~isfinite(orders)) || any(abs(orders - round(orders)) > eps)
        error('orders must contain finite integer diffraction orders.');
    end
    orders = round(orders);

    thetaIncidentRad = deg2rad(double(incident_angle_deg));
    sinThetaM = (double(n_in) * sin(thetaIncidentRad) + ...
        orders .* double(wavelength_um) ./ double(period_um)) ./ double(n_out);
    propagating = abs(sinThetaM) <= 1;
    thetaMRad = NaN(size(orders));
    thetaMRad(propagating) = asin(sinThetaM(propagating));
    thetaMDeg = rad2deg(thetaMRad);

    orderTable = table( ...
        orders, ...
        sinThetaM, ...
        propagating, ...
        thetaMDeg, ...
        thetaMRad, ...
        repmat(double(wavelength_um), numel(orders), 1), ...
        repmat(double(period_um), numel(orders), 1), ...
        repmat(double(incident_angle_deg), numel(orders), 1), ...
        repmat(double(n_in), numel(orders), 1), ...
        repmat(double(n_out), numel(orders), 1), ...
        'VariableNames', { ...
        'diffraction_order', ...
        'sin_theta_m', ...
        'is_propagating', ...
        'theta_m_deg', ...
        'u0', ...
        'wavelength_um', ...
        'grating_period_um', ...
        'incident_angle_deg', ...
        'n_in', ...
        'n_out'});

    idx = find(propagating);
    nPropagating = numel(idx);
    rayName = "m_" + signed_order_text_local(orders(idx));

    rays = table();
    rays.ray_name = rayName;
    rays.name = rayName;
    rays.z0 = repmat(double(z_obj), nPropagating, 1);
    rays.y0 = repmat(double(y_obj), nPropagating, 1);
    rays.u0 = thetaMRad(idx);
    rays.diffraction_order = orders(idx);
    rays.wavelength_um = repmat(double(wavelength_um), nPropagating, 1);
    rays.grating_period_um = repmat(double(period_um), nPropagating, 1);
    rays.incident_angle_deg = repmat(double(incident_angle_deg), ...
        nPropagating, 1);
    rays.theta_m_deg = thetaMDeg(idx);
    rays.sin_theta_m = sinThetaM(idx);
    rays.n_in = repmat(double(n_in), nPropagating, 1);
    rays.n_out = repmat(double(n_out), nPropagating, 1);
    rays.object_type = repmat("transmission grating", nPropagating, 1);

    info = struct();
    info.order_table = orderTable;
    info.n_propagating = nPropagating;
    info.n_nonpropagating = sum(~propagating);
    info.status_text = sprintf( ...
        'Grating orders: %d propagating, %d non-propagating.', ...
        info.n_propagating, info.n_nonpropagating);
end


function validate_scalar_finite_local(value, name)
    if ~isnumeric(value) || ~isscalar(value) || ~isfinite(value)
        error('%s must be a finite numeric scalar.', name);
    end
end


function validate_scalar_positive_local(value, name)
    validate_scalar_finite_local(value, name);
    if value <= 0
        error('%s must be positive.', name);
    end
end


function text = signed_order_text_local(orders)
    text = strings(numel(orders), 1);
    for k = 1:numel(orders)
        if orders(k) > 0
            text(k) = "+" + string(orders(k));
        else
            text(k) = string(orders(k));
        end
    end
end
