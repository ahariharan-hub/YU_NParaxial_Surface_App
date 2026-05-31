function lines = nparaxial_matrix_chain_text_yu(chain)
%NPARAXIAL_MATRIX_CHAIN_TEXT_YU Build readable matrix-chain text.

    if ~isstruct(chain) || ~isfield(chain, 'steps') || ...
            ~isfield(chain, 'final_matrix')
        error('chain must be a struct returned by nparaxial_matrix_chain_yu.');
    end

    factors = string(chain.factor_labels(:));
    productLines = wrap_product_local(flipud(factors), 105);
    factorList = factor_list_local(factors);

    lines = [
        "Matrix-chain convention"
        "-----------------------"
        "Rows in the table are chronological propagation steps."
        "For r_out = M*r_in, symbolic matrix multiplication is right-to-left."
        "Rows labeled T(0) same-plane separator preserve same-plane event order."
        "M ="
        "  " + productLines
        ""
        "Chronological factor list"
        "-------------------------"
        factorList
        ""
        nparaxial_matrix_to_text_yu(chain.final_matrix, "Final cumulative M")
        ];
end


function lines = wrap_product_local(factors, maxChars)
    if isempty(factors)
        lines = "I";
        return
    end

    lines = strings(0, 1);
    current = factors(1);
    for k = 2:numel(factors)
        candidate = current + " * " + factors(k);
        if strlength(candidate) > maxChars
            lines(end+1, 1) = current + " *"; %#ok<AGROW>
            current = factors(k);
        else
            current = candidate;
        end
    end
    lines(end+1, 1) = current;
end


function lines = factor_list_local(factors)
    if isempty(factors)
        lines = "  (none)";
        return
    end

    lines = strings(numel(factors), 1);
    for k = 1:numel(factors)
        lines(k) = "  " + string(k) + ". " + factors(k);
    end
end
