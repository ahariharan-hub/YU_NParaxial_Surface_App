function summary = nparaxial_vignetting_summary_yu(vig)
%NPARAXIAL_VIGNETTING_SUMMARY_YU Compact text/table vignetting summary.

    if ~isstruct(vig)
        error('vig must be a vignetting diagnostics struct.');
    end

    lines = {
        'Vignetting interval diagnostics'
        '--------------------------------'
        sprintf('Object field height y = %.6g', vig.y_obj)
        'First-order meridional y-u diagnostics.'
        'Lower and upper cone limits may be set by different apertures.'
        sprintf('Final u0 interval = [%.12g, %.12g]', ...
            vig.u_low, vig.u_high)
        sprintf('Interval center = %.12g', vig.u_center)
        sprintf('Interval semi-width = %.12g', vig.u_semi_width)
        sprintf('Fully vignetted = %s', logical_text_local(vig.fully_vignetted))
        sprintf('Lower limiting aperture = %s', vig.lower_bound_element_id)
        sprintf('Upper limiting aperture = %s', vig.upper_bound_element_id)
        sprintf('Symmetric about u0 = 0 = %s', logical_text_local(vig.is_symmetric))
        sprintf('Partially vignetted relative to axial = %s', ...
            logical_text_local(vig.partially_vignetted_relative_to_axial))
        char(vig.note)
        };

    quantity = [
        "y_obj"
        "z_obj"
        "z_end"
        "u_low"
        "u_high"
        "u_center"
        "u_semi_width"
        "fully_vignetted"
        "lower_bound_element_id"
        "lower_bound_event_index"
        "upper_bound_element_id"
        "upper_bound_event_index"
        "is_symmetric"
        "axial_u_low"
        "axial_u_high"
        "axial_u_center"
        "axial_u_semi_width"
        "partially_vignetted_relative_to_axial"
        "note"
        ];

    value = [
        string(vig.y_obj)
        string(vig.z_obj)
        string(vig.z_end)
        string(vig.u_low)
        string(vig.u_high)
        string(vig.u_center)
        string(vig.u_semi_width)
        string(vig.fully_vignetted)
        string(vig.lower_bound_element_id)
        string(vig.lower_bound_event_index)
        string(vig.upper_bound_element_id)
        string(vig.upper_bound_event_index)
        string(vig.is_symmetric)
        string(vig.axial_u_low)
        string(vig.axial_u_high)
        string(vig.axial_u_center)
        string(vig.axial_u_semi_width)
        string(vig.partially_vignetted_relative_to_axial)
        string(vig.note)
        ];

    summary = struct();
    summary.lines = lines;
    summary.table = table(quantity, value);
end


function text = logical_text_local(value)
    if value
        text = 'true';
    else
        text = 'false';
    end
end
