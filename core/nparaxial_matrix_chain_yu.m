function chain = nparaxial_matrix_chain_yu(prescription, z_in, z_out)
%NPARAXIAL_MATRIX_CHAIN_YU Build chronological ABCD matrix-chain steps.
%
% Rows are ordered in physical propagation order. Cumulative matrices follow
% r_after_step = M_cumulative*r_input, so the symbolic product is read
% right-to-left.

    if ~isscalar(z_in) || ~isscalar(z_out) || ...
            ~isfinite(z_in) || ~isfinite(z_out)
        error('z_in and z_out must be finite scalar values.');
    end
    if z_out < z_in
        error('Forward propagation requires z_out >= z_in.');
    end

    events = nparaxial_event_sequence_yu(prescription, z_in, z_out);
    T = empty_chain_table_local();
    factorLabels = strings(0, 1);

    M = eye(2);
    zCurr = z_in;
    stepIndex = 0;

    for k = 1:height(events)
        event = events(k, :);
        zElement = event.z(1);
        d = zElement - zCurr;
        if d < -1e-12
            error('Matrix-chain events must be ordered forward in z.');
        end

        stepIndex = stepIndex + 1;
        X = [1, d; 0, 1];
        label = translation_label_local(d);
        [T, M] = append_step_local( ...
            T, stepIndex, "translation", "", "", zCurr, zElement, d, ...
            label, X, M);
        factorLabels(end+1, 1) = string(label); %#ok<AGROW>

        stepIndex = stepIndex + 1;
        E = nparaxial_element_matrix_yu(event);
        label = element_label_local(event);
        [T, M] = append_step_local( ...
            T, stepIndex, event.type(1), event.element_id(1), ...
            event.type(1), zElement, zElement, 0, label, E, M);
        factorLabels(end+1, 1) = string(label); %#ok<AGROW>

        zCurr = zElement;
    end

    d = z_out - zCurr;
    stepIndex = stepIndex + 1;
    X = [1, d; 0, 1];
    label = translation_label_local(d);
    [T, M] = append_step_local( ...
        T, stepIndex, "translation", "", "", zCurr, z_out, d, ...
        label, X, M);
    factorLabels(end+1, 1) = string(label);

    chain = struct();
    chain.z_in = z_in;
    chain.z_out = z_out;
    chain.steps = T;
    chain.final_matrix = M;
    chain.factor_labels = factorLabels;
    chain.product_order_note = ...
        "Rows are chronological; symbolic multiplication is right-to-left.";
end


function [T, M] = append_step_local( ...
    T, stepIndex, operationType, elementId, typeName, zStart, zEnd, d, ...
    matrixLabel, X, M)

    M = X * M;
    T(end+1, :) = { ...
        stepIndex, string(operationType), string(elementId), string(typeName), ...
        zStart, zEnd, d, string(matrixLabel), ...
        X(1, 1), X(1, 2), X(2, 1), X(2, 2), ...
        M(1, 1), M(1, 2), M(2, 1), M(2, 2)}; %#ok<AGROW>
end


function label = translation_label_local(d)
    if abs(d) <= 1e-12
        label = 'T(0) same-plane separator';
    else
        label = sprintf('T(%.12g)', d);
    end
end


function label = element_label_local(event)
    id = char(event.element_id(1));
    switch event.type(1)
        case "thinlens"
            label = sprintf('L_%s(f=%.12g)', id, event.focal_length(1));

        case "surface"
            label = sprintf('S_%s(n1=%.12g,n2=%.12g,R=%.12g)', ...
                id, event.n_before(1), event.n_after(1), event.radius_R(1));

        case "stop"
            label = sprintf('I_%s(stop)', id);

        case "dummy"
            label = sprintf('I_%s(dummy)', id);

        otherwise
            label = sprintf('E_%s', id);
    end
end


function T = empty_chain_table_local()
    T = table( ...
        zeros(0, 1), strings(0, 1), strings(0, 1), strings(0, 1), ...
        zeros(0, 1), zeros(0, 1), zeros(0, 1), strings(0, 1), ...
        zeros(0, 1), zeros(0, 1), zeros(0, 1), zeros(0, 1), ...
        zeros(0, 1), zeros(0, 1), zeros(0, 1), zeros(0, 1), ...
        'VariableNames', { ...
        'step_index', 'operation_type', 'element_id', 'type', ...
        'z_start', 'z_end', 'd', 'matrix_label', ...
        'A', 'B', 'C', 'D', ...
        'cumulative_A', 'cumulative_B', 'cumulative_C', 'cumulative_D'});
end
