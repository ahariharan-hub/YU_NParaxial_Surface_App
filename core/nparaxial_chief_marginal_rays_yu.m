function diag = nparaxial_chief_marginal_rays_yu( ...
    prescription, z_obj, y_obj, z_final, selected_event_index, tol)
%NPARAXIAL_CHIEF_MARGINAL_RAYS_YU Trace chief and marginal rays via a stop.

    if nargin < 6 || isempty(tol)
        tol = 1e-12;
    end
    if ~isscalar(z_obj) || ~isfinite(z_obj) || ...
            ~isscalar(y_obj) || ~isfinite(y_obj) || ...
            ~isscalar(z_final) || ~isfinite(z_final)
        error('z_obj, y_obj, and z_final must be finite scalars.');
    end

    events = nparaxial_event_sequence_yu(prescription);
    if nargin < 5 || isempty(selected_event_index) || isnan(selected_event_index)
        stopDiag = nparaxial_select_aperture_stop_yu(prescription, z_obj, y_obj, tol);
        selected_event_index = stopDiag.selected_event_index;
    end

    stopEvent = events(events.event_index == selected_event_index, :);
    if isempty(stopEvent)
        error('Selected stop event_index %.12g was not found.', selected_event_index);
    end
    aStop = stopEvent.aperture_radius(1);
    if ~isfinite(aStop) || aStop <= 0
        error('Selected stop must have finite positive aperture_radius.');
    end

    preEvents = events(events.event_index < stopEvent.event_index, :);
    Mpre = nparaxial_partial_system_matrix_yu(preEvents, z_obj, stopEvent.z(1));
    A = Mpre(1, 1);
    B = Mpre(1, 2);
    if abs(B) <= tol
        error('Cannot solve chief/marginal launch slopes because B to stop is near zero.');
    end

    rayName = ["chief"; "upper_marginal"; "lower_marginal"];
    targetStopY = [0; aStop; -aStop];
    u0 = (targetStopY - A*y_obj) ./ B;

    rays = table;
    rays.name = rayName;
    rays.z0 = repmat(z_obj, 3, 1);
    rays.y0 = repmat(y_obj, 3, 1);
    rays.u0 = u0;
    rays.z_target = repmat(stopEvent.z(1), 3, 1);
    rays.y_target = targetStopY;

    bundle = nparaxial_trace_bundle_yu(rays, prescription, z_final);
    rayTable = table;
    rayTable.name = rayName;
    rayTable.target_stop_y = targetStopY;
    rayTable.u0 = u0;
    rayTable.traced = [bundle.trc].';
    rayTable.y_final = [bundle.yf].';
    rayTable.u_final = [bundle.uf].';
    rayTable.blocked_element_id = strings(3, 1);
    rayTable.blocked_z = NaN(3, 1);
    rayTable.blocked_y = NaN(3, 1);
    rayTable.blocked_aperture = NaN(3, 1);

    eventTable = empty_event_table_local();
    for k = 1:numel(bundle)
        res = bundle(k).res;
        rayTable.blocked_element_id(k) = res.blocked_element_id;
        rayTable.blocked_z(k) = res.blocked_at_z;
        rayTable.blocked_y(k) = res.blocked_y;
        rayTable.blocked_aperture(k) = res.blocked_aperture;

        E = res.events;
        for q = 1:height(E)
            eventTable(end+1, :) = { ...
                bundle(k).name, E.index(q), E.element_id(q), E.type(q), ...
                E.z(q), E.aperture_radius(q), E.n_before(q), E.n_after(q), ...
                E.y_before(q), E.u_before(q), E.passed_aperture(q), ...
                E.y_after(q), E.u_after(q), res.blocked_element_id, ...
                res.blocked_at_z, res.blocked_aperture}; %#ok<AGROW>
        end
    end

    diag = struct();
    diag.stop_event = stopEvent;
    diag.M_pre = Mpre;
    diag.rays = rays;
    diag.bundle = bundle;
    diag.ray_table = rayTable;
    diag.event_table = eventTable;
end


function T = empty_event_table_local()
    T = table( ...
        strings(0, 1), zeros(0, 1), strings(0, 1), strings(0, 1), ...
        zeros(0, 1), zeros(0, 1), zeros(0, 1), zeros(0, 1), ...
        zeros(0, 1), zeros(0, 1), false(0, 1), zeros(0, 1), ...
        zeros(0, 1), strings(0, 1), zeros(0, 1), zeros(0, 1), ...
        'VariableNames', { ...
        'ray_name', 'event_index_trace', 'element_id', 'type', ...
        'z', 'aperture_radius', 'n_before', 'n_after', ...
        'y_before', 'u_before', 'passed_aperture', 'y_after', ...
        'u_after', 'blocked_element_id', 'blocked_z', 'blocked_aperture'});
end
