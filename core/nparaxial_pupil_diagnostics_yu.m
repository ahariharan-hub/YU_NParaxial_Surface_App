function pupil = nparaxial_pupil_diagnostics_yu( ...
    prescription, z_front, z_rear, selected_event_index, tol)
%NPARAXIAL_PUPIL_DIAGNOSTICS_YU Entrance and exit pupil diagnostics.

    if nargin < 5 || isempty(tol)
        tol = 1e-12;
    end

    events = nparaxial_event_sequence_yu(prescription);
    if isempty(events)
        error('At least one enabled event is required.');
    end
    if nargin < 2 || isempty(z_front)
        z_front = events.z(1);
    end
    if nargin < 3 || isempty(z_rear)
        z_rear = events.z(end);
    end
    if nargin < 4 || isempty(selected_event_index) || isnan(selected_event_index)
        stopDiag = nparaxial_select_aperture_stop_yu(prescription, z_front, 0, tol);
        selected_event_index = stopDiag.selected_event_index;
    end
    if z_rear < z_front
        error('z_rear must be greater than or equal to z_front.');
    end

    stopMask = events.event_index == selected_event_index;
    if ~any(stopMask)
        error('Selected stop event_index %.12g was not found.', selected_event_index);
    end

    stopEvent = events(find(stopMask, 1), :);
    aStop = stopEvent.aperture_radius(1);
    if ~isfinite(aStop) || aStop <= 0
        error('Selected stop must have finite positive aperture_radius.');
    end

    preEvents = events(events.event_index < stopEvent.event_index, :);

    % Aperture clipping happens at the selected event plane before the event
    % matrix is applied. If the selected finite aperture belongs to a
    % powered element, image-space pupil imaging must include that powered
    % event after the aperture plane. Identity stop/dummy events can be
    % excluded because they do not change the ray.
    if ismember(stopEvent.type(1), ["thinlens", "surface"])
        postEvents = events(events.event_index >= stopEvent.event_index, :);
    else
        postEvents = events(events.event_index > stopEvent.event_index, :);
    end
    zStop = stopEvent.z(1);

    Mpre = nparaxial_partial_system_matrix_yu(preEvents, z_front, zStop);
    Apre = Mpre(1, 1);
    Bpre = Mpre(1, 2);

    Mpost = nparaxial_partial_system_matrix_yu(postEvents, zStop, z_rear);
    Bpost = Mpost(1, 2);
    Dpost = Mpost(2, 2);

    entranceFinite = abs(Apre) > tol;
    if entranceFinite
        zEP = z_front + Bpre/Apre;
        mEP = Apre;
        rEP = aStop/abs(Apre);
    else
        zEP = Inf;
        mEP = Inf;
        rEP = Inf;
    end

    exitFinite = abs(Dpost) > tol;
    if exitFinite
        xXP = -Bpost/Dpost;
        zXP = z_rear + xXP;
        MXP = [1, xXP; 0, 1] * Mpost;
        mXP = MXP(1, 1);
        rXP = abs(mXP) * aStop;
    else
        xXP = Inf;
        zXP = Inf;
        MXP = NaN(2, 2);
        mXP = Inf;
        rXP = Inf;
    end

    pupil = struct();
    pupil.z_front = z_front;
    pupil.z_rear = z_rear;
    pupil.stop_event = stopEvent;
    pupil.stop_event_index = stopEvent.event_index(1);
    pupil.stop_element_id = stopEvent.element_id(1);
    pupil.stop_z = zStop;
    pupil.stop_radius = aStop;
    pupil.pre_event_indices = preEvents.event_index;
    pupil.post_event_indices = postEvents.event_index;
    pupil.M_pre = Mpre;
    pupil.M_post = Mpost;
    pupil.entrance_is_finite = entranceFinite;
    pupil.z_EP = zEP;
    pupil.m_EP = mEP;
    pupil.r_EP = rEP;
    pupil.exit_is_finite = exitFinite;
    pupil.x_XP = xXP;
    pupil.z_XP = zXP;
    pupil.M_XP = MXP;
    pupil.m_XP = mXP;
    pupil.r_XP = rXP;

    quantity = [
        "stop_event_index"; "stop_z"; "stop_radius"; ...
        "entrance_is_finite"; "z_EP"; "m_EP"; "r_EP"; ...
        "exit_is_finite"; "x_XP"; "z_XP"; "m_XP"; "r_XP"
    ];
    value = [
        pupil.stop_event_index; pupil.stop_z; pupil.stop_radius; ...
        double(pupil.entrance_is_finite); pupil.z_EP; pupil.m_EP; pupil.r_EP; ...
        double(pupil.exit_is_finite); pupil.x_XP; pupil.z_XP; pupil.m_XP; pupil.r_XP
    ];
    pupil.table = table(quantity, value);
end
