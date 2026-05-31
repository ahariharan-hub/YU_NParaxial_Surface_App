function inv = nparaxial_lagrange_invariant_yu(chiefMarginalDiag, tol)
%NPARAXIAL_LAGRANGE_INVARIANT_YU Canonical invariant from ray pairs.
%
% H = n*(y1*u2 - y2*u1). The raw y-u area is reported but not assumed
% conserved when refractive index changes.

    if nargin < 2 || isempty(tol)
        tol = 1e-12;
    end

    bundle = chiefMarginalDiag.bundle;
    names = string({bundle.name}.');
    chiefIdx = find(names == "chief", 1);
    upperIdx = find(names == "upper_marginal", 1);
    lowerIdx = find(names == "lower_marginal", 1);

    T = empty_invariant_table_local();
    T = append_pair_local(T, bundle, chiefIdx, upperIdx, "chief_upper");
    T = append_pair_local(T, bundle, chiefIdx, lowerIdx, "chief_lower");

    pairNames = unique(T.pair, 'stable');
    summary = table( ...
        strings(0, 1), false(0, 1), zeros(0, 1), ...
        zeros(0, 1), zeros(0, 1), zeros(0, 1), zeros(0, 1), ...
        'VariableNames', { ...
        'pair', 'both_unblocked', 'invariant_valid_count', ...
        'H_initial', 'H_final', 'max_abs_H_delta', ...
        'max_abs_raw_yu_delta'});

    for k = 1:numel(pairNames)
        mask = T.pair == pairNames(k);
        validMask = mask & T.invariant_valid;
        H = T.canonical_H(validMask);
        raw = T.raw_yu_area(validMask);
        bothUnblocked = all(T.ray1_unblocked(mask) & T.ray2_unblocked(mask));
        if isempty(H)
            HInitial = NaN;
            HFinal = NaN;
            maxHDelta = NaN;
            maxRawDelta = NaN;
        else
            HInitial = H(1);
            HFinal = H(end);
            maxHDelta = max(abs(H - HInitial), [], 'omitnan');
            maxRawDelta = max(abs(raw - raw(1)), [], 'omitnan');
        end
        summary(end+1, :) = { ...
            pairNames(k), bothUnblocked, sum(validMask), HInitial, HFinal, ...
            maxHDelta, maxRawDelta}; %#ok<AGROW>
    end

    inv = struct();
    inv.table = T;
    inv.summary = summary;
    inv.tol = tol;
    inv.note = ["Canonical y-p area uses p = n*u; raw y-u area is not ", ...
        "asserted conserved when n changes. Samples are after-event states ", ...
        "at event planes; conservation is meaningful only where ", ...
        "invariant_valid is true."];
end


function T = append_pair_local(T, bundle, idx1, idx2, pairName)
    if isempty(idx1) || isempty(idx2)
        return
    end

    res1 = bundle(idx1).res;
    res2 = bundle(idx2).res;
    n = min(numel(res1.z_hist), numel(res2.z_hist));
    bothUnblocked = res1.trc && res2.trc;
    for k = 1:n
        z = res1.z_hist(k);
        nMedium = res1.n_hist(k);
        y1 = res1.y_hist(k);
        u1 = res1.u_hist(k);
        y2 = res2.y_hist(k);
        u2 = res2.u_hist(k);
        invariantValid = ray_state_valid_local(res1, z) && ...
            ray_state_valid_local(res2, z);
        if invariantValid
            raw = y1*u2 - y2*u1;
            H = nMedium * raw;
        else
            raw = NaN;
            H = NaN;
        end
        T(end+1, :) = { ...
            pairName, k, "after_event", z, nMedium, ...
            bundle(idx1).name, bundle(idx2).name, ...
            y1, u1, y2, u2, raw, H, ...
            res1.trc, res2.trc, bothUnblocked, invariantValid}; %#ok<AGROW>
    end
end


function isValid = ray_state_valid_local(res, z)
    if res.trc
        isValid = true;
        return
    end

    if ~isfinite(res.blocked_at_z)
        isValid = false;
        return
    end

    isValid = z < res.blocked_at_z - 1e-12;
end


function T = empty_invariant_table_local()
    T = table( ...
        strings(0, 1), zeros(0, 1), strings(0, 1), ...
        zeros(0, 1), zeros(0, 1), ...
        strings(0, 1), strings(0, 1), zeros(0, 1), zeros(0, 1), ...
        zeros(0, 1), zeros(0, 1), zeros(0, 1), zeros(0, 1), ...
        false(0, 1), false(0, 1), false(0, 1), false(0, 1), ...
        'VariableNames', { ...
        'pair', 'plane_index', 'state_side', 'z', 'n', 'ray1', 'ray2', ...
        'y1', 'u1', 'y2', 'u2', 'raw_yu_area', 'canonical_H', ...
        'ray1_unblocked', 'ray2_unblocked', 'both_unblocked', ...
        'invariant_valid'});
end
