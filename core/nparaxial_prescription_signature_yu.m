function sig = nparaxial_prescription_signature_yu(prescription)
%NPARAXIAL_PRESCRIPTION_SIGNATURE_YU Deterministic prescription signature.
%
% The signature is a conservative normalized-text representation of the
% active prescription table contents. It intentionally includes row order,
% event order, enabled flags, optical parameters, and apertures.

    T = nparaxial_validate_prescription_yu(prescription);
    names = string(T.Properties.VariableNames);
    lines = strings(height(T) + 1, 1);
    lines(1) = "nparaxial_prescription_signature_v1|" + ...
        strjoin(cellstr(names), "|");

    for r = 1:height(T)
        pieces = strings(numel(names), 1);
        for c = 1:numel(names)
            value = T.(names(c))(r);
            pieces(c) = names(c) + "=" + encode_value_local(value);
        end
        lines(r + 1) = "row" + string(r) + "|" + ...
            strjoin(cellstr(pieces), "|");
    end

    sig = strjoin(cellstr(lines), newline);
    sig = string(sig);
end


function text = encode_value_local(value)
    if isstring(value) || ischar(value)
        text = string(value);
    elseif islogical(value)
        text = string(double(value));
    elseif isnumeric(value)
        value = double(value);
        if isinf(value)
            if value > 0
                text = "Inf";
            else
                text = "-Inf";
            end
        elseif isnan(value)
            text = "NaN";
        else
            text = string(sprintf('%.17g', value));
        end
    else
        text = string(value);
    end

    text = replace(text, "\", "\\");
    text = replace(text, "|", "\|");
    text = replace(text, newline, "\n");
end
