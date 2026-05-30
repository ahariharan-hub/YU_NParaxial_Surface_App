function assert_prescriptions_equal_yu(expected, actual, tol)
%ASSERT_PRESCRIPTIONS_EQUAL_YU Compare normalized prescription tables.

    if nargin < 3
        tol = 1e-12;
    end

    expected = nparaxial_validate_prescription_yu(expected);
    actual = nparaxial_validate_prescription_yu(actual);

    assert(height(expected) == height(actual), ...
        'Prescription row counts differ.');
    assert(isequal(expected.element_id, actual.element_id), ...
        'element_id values differ.');
    assert(isequal(expected.type, actual.type), ...
        'type values differ.');
    assert(isequal(expected.enabled, actual.enabled), ...
        'enabled values differ.');

    numericColumns = [
        "event_order"
        "z"
        "aperture_radius"
        "focal_length"
        "radius_R"
        "n_before"
        "n_after"
    ];

    for k = 1:numel(numericColumns)
        columnName = numericColumns(k);
        a = expected.(columnName);
        b = actual.(columnName);
        sameInf = isinf(a) & isinf(b) & sign(a) == sign(b);
        close = abs(a - b) <= tol;
        assert(all(sameInf | close), ...
            'Numeric column "%s" differs.', columnName);
    end
end
