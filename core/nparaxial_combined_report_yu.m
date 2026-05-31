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
        lines = add_line_local(lines, "Warning: " + diagnostics.off_axis_warning);
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
        lines = append_table_local(lines, "Aperture stop candidates", ...
            diagnostics.stop.candidate_table);
        if ~isempty(diagnostics.pupil)
            lines = append_table_local(lines, "Pupil", diagnostics.pupil.table);
        elseif strlength(diagnostics.pupil_error) > 0
            lines = append_section_local(lines, "Pupil", ...
                "Unavailable: " + diagnostics.pupil_error);
        end
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
        "Stop selection is axial-first-order in this milestone."
        "Full off-axis vignetting interval analysis is not implemented in Milestone 2.2."
        "r = [y;u] is not canonical when n changes; canonical p = n*u."
    ];
    if isfield(diagnostics, 'off_axis_warning') && ...
            strlength(diagnostics.off_axis_warning) > 0
        warnings(end+1, 1) = "Off-axis warning: " + diagnostics.off_axis_warning;
    end
    lines = append_section_local(lines, "Limitations/warnings", warnings);
end


function lines = append_table_local(lines, titleText, T)
    lines = add_line_local(lines, titleText);
    lines = add_line_local(lines, repmat('-', 1, strlength(titleText)));
    if ~istable(T) || isempty(T)
        lines = add_line_local(lines, "(empty or unavailable)");
        lines = add_line_local(lines, "");
        return
    end

    text = string(evalc('disp(T)'));
    rows = splitlines(text);
    rows = rows(strlength(rows) > 0);
    lines = [lines; rows(:); ""]; %#ok<AGROW>
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
