function segmentTable = nparaxial_trace_segments_table_yu(bundleSet, tol)
%NPARAXIAL_TRACE_SEGMENTS_TABLE_YU Convert traced bundles to segment rows.
%
% Segment diagnostics compare the paraxial translation y2 = y1 + d*u with
% the scalar exact-angle expression y2 = y1 + d*tan(u). They do not alter
% the stored trace.

    if nargin < 2 || isempty(tol)
        tol = 1e-12;
    end

    rayName = strings(0, 1);
    fieldIndex = zeros(0, 1);
    segmentIndex = zeros(0, 1);
    zStart = zeros(0, 1);
    zEnd = zeros(0, 1);
    dVals = zeros(0, 1);
    nVals = zeros(0, 1);
    yStart = zeros(0, 1);
    yEnd = zeros(0, 1);
    uVals = zeros(0, 1);
    segmentKind = strings(0, 1);

    for q = 1:numel(bundleSet)
        if ~isfield(bundleSet(q), 'bundle')
            continue
        end
        bundle = bundleSet(q).bundle;
        fieldId = field_index_local(bundleSet(q), q);
        for r = 1:numel(bundle)
            if ~isfield(bundle(r), 'res') || isempty(bundle(r).res)
                continue
            end
            res = bundle(r).res;
            for s = 1:numel(res.seg_z)
                zSeg = double(res.seg_z{s});
                ySeg = double(res.seg_y{s});
                if numel(zSeg) < 2 || numel(ySeg) < 2
                    continue
                end

                rayName(end+1, 1) = string(bundle(r).name); %#ok<AGROW>
                fieldIndex(end+1, 1) = fieldId; %#ok<AGROW>
                segmentIndex(end+1, 1) = s; %#ok<AGROW>
                zStart(end+1, 1) = zSeg(1); %#ok<AGROW>
                zEnd(end+1, 1) = zSeg(end); %#ok<AGROW>
                d = zSeg(end) - zSeg(1);
                dVals(end+1, 1) = d; %#ok<AGROW>
                nVals(end+1, 1) = segment_medium_local(res, s); %#ok<AGROW>
                yStart(end+1, 1) = ySeg(1); %#ok<AGROW>
                yEnd(end+1, 1) = ySeg(end); %#ok<AGROW>
                uVals(end+1, 1) = segment_slope_local(res, s); %#ok<AGROW>
                segmentKind(end+1, 1) = ...
                    segment_kind_local(res, s, d, tol); %#ok<AGROW>
            end
        end
    end

    metrics = nparaxial_angle_validity_metrics_yu(uVals, tol);
    deltaY = dVals .* metrics.tan_minus_u;
    isZeroLength = abs(dVals) <= tol;
    deltaY(isZeroLength) = 0;
    levels = nparaxial_validity_warning_level_yu( ...
        uVals, metrics.relative_tan_error, false(size(uVals)), ...
        ~metrics.numeric_valid | ~metrics.tan_valid);

    segmentTable = table;
    segmentTable.ray_name = rayName;
    segmentTable.field_index = fieldIndex;
    segmentTable.segment_index = segmentIndex;
    segmentTable.z_start = zStart;
    segmentTable.z_end = zEnd;
    segmentTable.d = dVals;
    segmentTable.segment_kind = segmentKind;
    segmentTable.is_zero_length = isZeroLength;
    segmentTable.n = nVals;
    segmentTable.y_start = yStart;
    segmentTable.y_end_paraxial = yEnd;
    segmentTable.u = uVals;
    segmentTable.angle_deg = metrics.angle_deg;
    segmentTable.tan_minus_u = metrics.tan_minus_u;
    segmentTable.sin_minus_u = metrics.sin_minus_u;
    segmentTable.cos_minus_1 = metrics.cos_minus_1;
    segmentTable.relative_tan_error = metrics.relative_tan_error;
    segmentTable.relative_sin_error = metrics.relative_sin_error;
    segmentTable.delta_y_translation = deltaY;
    segmentTable.warning_level = levels;
end


function kind = segment_kind_local(res, s, d, tol)
    if abs(d) > tol
        kind = "translation";
        return
    end
    if isfield(res, 'events') && istable(res.events) && height(res.events) >= s
        kind = "same_plane_angle_sample";
    else
        kind = "zero_length_final";
    end
end


function fieldId = field_index_local(bundleSetRow, fallback)
    fieldId = fallback;
    if isfield(bundleSetRow, 'field_index') && ...
            isfinite(bundleSetRow.field_index)
        fieldId = bundleSetRow.field_index;
    end
end


function nVal = segment_medium_local(res, s)
    nVal = NaN;
    if isfield(res, 'seg_n') && numel(res.seg_n) >= s
        value = res.seg_n{s};
        if ~isempty(value)
            nVal = double(value(1));
        end
    end
end


function uVal = segment_slope_local(res, s)
    uVal = NaN;
    if isfield(res, 'events') && istable(res.events) && ...
            height(res.events) >= s && isfinite(res.events.u_before(s))
        uVal = res.events.u_before(s);
    elseif isfield(res, 'seg_z') && isfield(res, 'seg_y') && ...
            numel(res.seg_z) >= s && numel(res.seg_y) >= s
        zSeg = double(res.seg_z{s});
        ySeg = double(res.seg_y{s});
        d = zSeg(end) - zSeg(1);
        if abs(d) > 0
            uVal = (ySeg(end) - ySeg(1)) / d;
        elseif isfield(res, 'u_last') && isfinite(res.u_last)
            uVal = res.u_last;
        end
    end
end
