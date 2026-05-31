function lines = nparaxial_combined_report_yu( ...
    prescription, matrixTable, img, diagnostics, summaryLines)
%NPARAXIAL_COMBINED_REPORT_YU Build a first-order diagnostics text report.

    if nargin < 5
        summaryLines = strings(0, 1);
    end

    lines = strings(0, 1);
    lines = add_line_local(lines, "N-paraxial first-order combined report");
    lines = add_line_local(lines, "======================================");
    lines = add_line_local(lines, "");
    lines = add_line_local(lines, sprintf( ...
        "Diagnostic field height y = %.12g", diagnostics.diagnostic_field_y));
    lines = add_line_local(lines, "Field label: " + diagnostics.field_label);
    if isfield(diagnostics, 'off_axis_warning') && ...
            strlength(diagnostics.off_axis_warning) > 0
        lines = add_line_local(lines, "Off-axis note: " + diagnostics.off_axis_warning);
    end
    lines = add_line_local(lines, "");

    lines = append_section_local(lines, "Summary", string(summaryLines(:)));
    lines = append_table_local(lines, "Prescription", prescription);
    lines = append_table_local(lines, "System matrix", matrixTable);

    lines = add_line_local(lines, "Image plane");
    lines = add_line_local(lines, "-----------");
    lines = add_line_local(lines, sprintf("z_object = %.12g", img.z_obj));
    lines = add_line_local(lines, sprintf("z_reference = %.12g", img.z_ref));
    lines = add_line_local(lines, sprintf("z_image = %.12g", img.z_img));
    lines = add_line_local(lines, sprintf("x_after_reference = %.12g", img.x_after_ref));
    lines = add_line_local(lines, sprintf("magnification = %.12g", img.m));
    lines = add_line_local(lines, sprintf("B_residual = %.12g", img.B_residual));
    lines = add_line_local(lines, "");

    if isempty(diagnostics.cardinal)
        lines = append_section_local(lines, "Cardinal", ...
            "Unavailable: " + diagnostics.cardinal_error);
    else
        lines = append_table_local(lines, "Cardinal", diagnostics.cardinal.table);
    end

    if isempty(diagnostics.stop)
        lines = append_section_local(lines, "Aperture stop / pupil", ...
            "Unavailable: " + diagnostics.stop_error);
    else
        lines = append_selected_stop_local(lines, diagnostics);
        lines = append_table_local(lines, "Aperture stop candidates", ...
            diagnostics.stop.candidate_table);
        if ~isempty(diagnostics.pupil)
            lines = append_table_local(lines, "Pupil", diagnostics.pupil.table);
        elseif strlength(diagnostics.pupil_error) > 0
            lines = append_section_local(lines, "Pupil", ...
                "Unavailable: " + diagnostics.pupil_error);
        end
    end

    if isfield(diagnostics, 'vignetting') && ~isempty(diagnostics.vignetting)
        lines = append_vignetting_local(lines, diagnostics);
    elseif isfield(diagnostics, 'vignetting_error') && ...
            strlength(diagnostics.vignetting_error) > 0
        lines = append_section_local(lines, "Vignetting intervals", ...
            "Unavailable: " + diagnostics.vignetting_error);
    end

    if isempty(diagnostics.chief_marginal)
        lines = append_section_local(lines, "Chief/marginal", ...
            "Unavailable: " + diagnostics.chief_error);
    else
        lines = append_table_local(lines, "Chief/marginal rays", ...
            diagnostics.chief_marginal.ray_table);
        lines = append_table_local(lines, "Chief/marginal event trace", ...
            diagnostics.chief_marginal.event_table);
    end

    if isempty(diagnostics.invariant)
        lines = append_section_local(lines, "Invariant", ...
            "Unavailable: " + diagnostics.invariant_error);
    else
        lines = append_table_local(lines, "Invariant summary", ...
            diagnostics.invariant.summary);
        lines = append_table_local(lines, "Invariant samples", ...
            diagnostics.invariant.table);
    end

    lines = append_table_local(lines, "Phase space", diagnostics.phase_space);

    warnings = [
        "Limitations / warnings"
        "----------------------"
        "Paraxial first-order model only."
        "Meridional y-z plane only."
        "No exact Snell tracing."
        "No Seidel aberration calculation."
        "No lithography optimization."
        "Axial aperture stop selection remains distinct from off-axis lower/upper cone limiting apertures."
        "Off-axis vignetting intervals are first-order meridional diagnostics, not full 3D pupil analysis."
        "r = [y;u] is not canonical when n changes; canonical p = n*u."
    ];
    if isfield(diagnostics, 'off_axis_warning') && ...
            strlength(diagnostics.off_axis_warning) > 0
        warnings(end+1, 1) = "Off-axis note: " + diagnostics.off_axis_warning;
    end
    lines = append_section_local(lines, "Limitations/warnings", warnings);
end


function lines = append_vignetting_local(lines, diagnostics)
    vig = diagnostics.vignetting;
    if isfield(diagnostics, 'vignetting_summary') && ...
            ~isempty(diagnostics.vignetting_summary)
        summary = diagnostics.vignetting_summary;
    else
        summary = nparaxial_vignetting_summary_yu(vig);
    end

    lines = append_section_local(lines, "Vignetting intervals", ...
        string(summary.lines(:)));
    lines = append_table_local(lines, "Vignetting summary", summary.table);
    lines = append_table_local(lines, "Vignetting aperture intervals", ...
        vig.candidate_table);
    lines = append_table_local(lines, "Vignetting cumulative interval", ...
        vig.cumulative_table);
end


function lines = append_selected_stop_local(lines, diagnostics)
    lines = add_line_local(lines, "Selected axial stop");
    lines = add_line_local(lines, "-------------------");
    lines = add_line_local(lines, ...
        "stop_selection_rule = Aperture stop is selected from the axial field y_obj = 0 using the tightest launch-slope interval.");

    stopDiag = diagnostics.stop;
    if ~stopDiag.has_stop
        lines = add_line_local(lines, "selected_axial_stop = none");
        lines = add_line_local(lines, "");
        return
    end

    stopType = "";
    if isfield(stopDiag, 'selected_event') && ~isempty(stopDiag.selected_event)
        stopType = string(stopDiag.selected_event.type(1));
    end

    lines = add_line_local(lines, ...
        "selected_axial_stop_element_id = " + string(stopDiag.selected_element_id));
    lines = add_line_local(lines, ...
        "selected_axial_stop_type = " + stopType);
    lines = add_line_local(lines, sprintf( ...
        "selected_axial_stop_event_index = %.12g", ...
        stopDiag.selected_event_index));
    lines = add_line_local(lines, sprintf( ...
        "selected_axial_stop_z = %.12g", stopDiag.selected_z));
    lines = add_line_local(lines, sprintf( ...
        "selected_axial_stop_aperture_radius = %.12g", ...
        stopDiag.selected_aperture_radius));
    lines = add_line_local(lines, "selected_axial_stop_note = " + ...
        string(stopDiag.note));

    if isfield(diagnostics, 'off_axis_warning') && ...
            strlength(diagnostics.off_axis_warning) > 0
        lines = add_line_local(lines, ...
            "off_axis_stop_note = Stop-targeted chief/marginal rays trace the selected field height through the axial stop; vignetting intervals report the off-axis lower and upper cone limits separately.");
    end
    lines = add_line_local(lines, "");
end


function lines = append_table_local(lines, titleText, T)
    lines = add_line_local(lines, titleText);
    lines = add_line_local(lines, repmat('-', 1, strlength(titleText)));
    if ~istable(T)
        lines = add_line_local(lines, "(unavailable)");
        lines = add_line_local(lines, "");
        return
    end

    tableLines = nparaxial_table_to_text_yu(T);
    if isempty(tableLines)
        lines = add_line_local(lines, "(empty or unavailable)");
        lines = add_line_local(lines, "");
        return
    end

    lines = [lines; tableLines(:); ""]; %#ok<AGROW>
end


function lines = append_section_local(lines, titleText, bodyLines)
    lines = add_line_local(lines, titleText);
    lines = add_line_local(lines, repmat('-', 1, strlength(titleText)));
    bodyLines = string(bodyLines(:));
    if isempty(bodyLines)
        lines = add_line_local(lines, "(empty)");
    else
        lines = [lines; bodyLines]; %#ok<AGROW>
    end
    lines = add_line_local(lines, "");
end


function lines = add_line_local(lines, line)
    lines(end+1, 1) = string(line);
end
