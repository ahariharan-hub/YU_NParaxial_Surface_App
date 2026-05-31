function diagnostics = nparaxial_field_diagnostics_yu( ...
    prescription, z_obj, z_img, y_field, tol)
%NPARAXIAL_FIELD_DIAGNOSTICS_YU Collect field-dependent first-order diagnostics.

    if nargin < 4 || isempty(y_field)
        y_field = 0;
    end
    if nargin < 5 || isempty(tol)
        tol = 1e-12;
    end
    if ~isscalar(z_obj) || ~isfinite(z_obj) || ...
            ~isscalar(z_img) || ~isfinite(z_img) || ...
            ~isscalar(y_field) || ~isfinite(y_field)
        error('z_obj, z_img, and y_field must be finite scalars.');
    end

    prescription = nparaxial_validate_prescription_yu(prescription);
    elements = nparaxial_enabled_elements_yu(prescription);
    zFront = elements.z(1);
    zRear = elements.z(end);
    isAxial = abs(y_field) <= tol;
    offAxisWarning = "";
    if ~isAxial
        offAxisWarning = ['Off-axis vignetting interval diagnostics are ', ...
            'first-order meridional diagnostics. Lower and upper cone ', ...
            'limits may be set by different apertures.'];
    end

    diagnostics = struct();
    diagnostics.z_front = zFront;
    diagnostics.z_rear = zRear;
    diagnostics.diagnostic_field_y = y_field;
    diagnostics.is_axial = isAxial;
    diagnostics.field_label = "axial";
    diagnostics.off_axis_warning = string(offAxisWarning);
    diagnostics.cardinal_error = "";
    diagnostics.stop_error = "";
    diagnostics.pupil_error = "";
    diagnostics.chief_error = "";
    diagnostics.invariant_error = "";
    diagnostics.vignetting_error = "";
    diagnostics.cardinal = [];
    diagnostics.stop = [];
    diagnostics.pupil = [];
    diagnostics.chief_marginal = [];
    diagnostics.invariant = [];
    diagnostics.phase_space = table();
    diagnostics.vignetting = [];
    diagnostics.vignetting_summary = [];

    if ~isAxial
        diagnostics.field_label = "off_axis_using_axial_stop";
    end

    try
        diagnostics.cardinal = nparaxial_cardinal_points_yu( ...
            prescription, zFront, zRear, tol);
    catch ME
        diagnostics.cardinal_error = string(ME.message);
    end

    try
        diagnostics.vignetting = nparaxial_vignetting_intervals_yu( ...
            prescription, z_obj, y_field, z_img, tol);
        diagnostics.vignetting_summary = nparaxial_vignetting_summary_yu( ...
            diagnostics.vignetting);
    catch ME
        diagnostics.vignetting_error = string(ME.message);
    end

    try
        diagnostics.stop = nparaxial_select_aperture_stop_yu( ...
            prescription, z_obj, 0, tol);
        if ~isempty(diagnostics.stop) && strlength(offAxisWarning) > 0
            diagnostics.stop.off_axis_warning = string(offAxisWarning);
            diagnostics.stop.note = diagnostics.stop.note + ...
                " Aperture stop selection remains axial; see vignetting interval diagnostics for off-axis cone limits.";
        end
    catch ME
        diagnostics.stop_error = string(ME.message);
    end

    if ~isempty(diagnostics.stop) && diagnostics.stop.has_stop
        selectedEvent = diagnostics.stop.selected_event_index;
        try
            diagnostics.pupil = nparaxial_pupil_diagnostics_yu( ...
                prescription, zFront, zRear, selectedEvent, tol);
        catch ME
            diagnostics.pupil_error = string(ME.message);
        end

        try
            diagnostics.chief_marginal = nparaxial_chief_marginal_rays_yu( ...
                prescription, z_obj, y_field, z_img, selectedEvent, tol);
        catch ME
            diagnostics.chief_error = string(ME.message);
        end

        if ~isempty(diagnostics.chief_marginal)
            try
                diagnostics.invariant = nparaxial_lagrange_invariant_yu( ...
                    diagnostics.chief_marginal, tol);
                diagnostics.phase_space = nparaxial_phase_space_table_yu( ...
                    diagnostics.chief_marginal);
            catch ME
                diagnostics.invariant_error = string(ME.message);
            end
        end
    end
end
