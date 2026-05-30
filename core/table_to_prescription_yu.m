function prescription = table_to_prescription_yu(T)
%TABLE_TO_PRESCRIPTION_YU Validate an editable table as a prescription.

    if ~istable(T)
        error('Input must be a MATLAB table.');
    end

    prescription = nparaxial_validate_prescription_yu(T);
end
