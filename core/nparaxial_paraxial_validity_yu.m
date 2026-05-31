function validity = nparaxial_paraxial_validity_yu( ...
    bundleSet, prescription, thresholds, tol)
%NPARAXIAL_PARAXIAL_VALIDITY_YU Top-level paraxial-validity diagnostics.
%
% Diagnostics are derived from already-traced paraxial ray bundles. The
% prescription argument is accepted for API symmetry and future extension.

    if nargin < 2
        prescription = table(); %#ok<NASGU>
    end
    if nargin < 3 || isempty(thresholds)
        thresholds = default_thresholds_local();
    end
    if nargin < 4 || isempty(tol)
        tol = 1e-12;
    end

    segmentTable = nparaxial_trace_segments_table_yu(bundleSet, tol);
    eventTable = nparaxial_event_validity_yu(bundleSet, tol);
    summaryTable = build_summary_table_local(bundleSet, segmentTable, eventTable);

    worstLevel = "ok";
    if ~isempty(summaryTable)
        worstLevel = max_level_array_local(summaryTable.worst_warning_level);
    end

    validity = struct();
    validity.summary_table = summaryTable;
    validity.segment_table = segmentTable;
    validity.event_table = eventTable;
    validity.thresholds = thresholds;
    validity.threshold_table = thresholds_table_local(thresholds);
    validity.status_text = sprintf( ...
        'Paraxial validity diagnostics evaluated %d rays; worst warning level = %s.', ...
        height(summaryTable), worstLevel);
    validity.note = [
        "Diagnostic only: main tracing remains paraxial."
        "u is the paraxial ray angle in radians."
        "Aperture-limited rays are geometrically admitted, not paraxial-validity certified."
        "Spherical-surface scalar validity is deferred to Milestone 2.3.4."
        ];
end


function summaryTable = build_summary_table_local(bundleSet, segmentTable, eventTable)
    rayName = strings(0, 1);
    fieldIndex = zeros(0, 1);
    samplingMode = strings(0, 1);
    blocked = false(0, 1);
    worstAngle = zeros(0, 1);
    worstTranslation = zeros(0, 1);
    worstPlaneDelta = zeros(0, 1);
    maxLensDeflection = zeros(0, 1);
    tirCount = zeros(0, 1);
    severeCount = zeros(0, 1);
    warningCount = zeros(0, 1);
    noticeCount = zeros(0, 1);
    worstLevel = strings(0, 1);
    worstLocation = strings(0, 1);

    for q = 1:numel(bundleSet)
        if ~isfield(bundleSet(q), 'bundle')
            continue
        end
        bundle = bundleSet(q).bundle;
        fieldId = field_index_local(bundleSet(q), q);
        rayTable = table();
        if isfield(bundleSet(q), 'rays') && istable(bundleSet(q).rays)
            rayTable = bundleSet(q).rays;
        end

        for r = 1:numel(bundle)
            name = string(bundle(r).name);
            segMask = segmentTable.ray_name == name & ...
                segmentTable.field_index == fieldId;
            evtMask = eventTable.ray_name == name & ...
                eventTable.field_index == fieldId;
            segRows = segmentTable(segMask, :);
            evtRows = eventTable(evtMask, :);
            translationSegRows = translation_segments_local(segRows);

            levels = [string(translationSegRows.warning_level); ...
                string(evtRows.warning_level)];
            if isempty(levels)
                levels = "ok";
            end

            rayName(end+1, 1) = name; %#ok<AGROW>
            fieldIndex(end+1, 1) = fieldId; %#ok<AGROW>
            samplingMode(end+1, 1) = sampling_mode_local(rayTable, r); %#ok<AGROW>
            blocked(end+1, 1) = ~bundle(r).trc; %#ok<AGROW>

            angleValues = [abs(segRows.angle_deg); ...
                abs(evtRows.angle_in_deg); abs(evtRows.angle_out_deg)];
            worstAngle(end+1, 1) = max_or_nan_local(angleValues); %#ok<AGROW>

            worstTranslation(end+1, 1) = signed_max_abs_local( ...
                translationSegRows.delta_y_translation); %#ok<AGROW>
            planeMask = evtRows.diagnostic_type == "plane_refraction";
            worstPlaneDelta(end+1, 1) = signed_max_abs_local( ...
                evtRows.delta_u(planeMask)); %#ok<AGROW>
            maxLensDeflection(end+1, 1) = max_or_nan_local( ...
                evtRows.abs_thinlens_deflection); %#ok<AGROW>
            tirCount(end+1, 1) = sum(evtRows.tir_flag); %#ok<AGROW>
            severeCount(end+1, 1) = sum(levels == "severe"); %#ok<AGROW>
            warningCount(end+1, 1) = sum(levels == "warning"); %#ok<AGROW>
            noticeCount(end+1, 1) = sum(levels == "notice"); %#ok<AGROW>
            worstLevel(end+1, 1) = max_level_array_local(levels); %#ok<AGROW>
            worstLocation(end+1, 1) = worst_location_local( ...
                translationSegRows, evtRows); %#ok<AGROW>
        end
    end

    summaryTable = table;
    summaryTable.ray_name = rayName;
    summaryTable.field_index = fieldIndex;
    summaryTable.sampling_mode = samplingMode;
    summaryTable.blocked = blocked;
    summaryTable.worst_angle_deg = worstAngle;
    summaryTable.worst_translation_delta_y = worstTranslation;
    summaryTable.worst_plane_refraction_delta_u = worstPlaneDelta;
    summaryTable.max_thinlens_deflection = maxLensDeflection;
    summaryTable.tir_count = tirCount;
    summaryTable.severe_count = severeCount;
    summaryTable.warning_count = warningCount;
    summaryTable.notice_count = noticeCount;
    summaryTable.worst_warning_level = worstLevel;
    summaryTable.worst_location_note = worstLocation;
end


function rows = translation_segments_local(segRows)
    rows = segRows;
    if isempty(rows)
        return
    end
    if ismember('segment_kind', rows.Properties.VariableNames)
        rows = rows(rows.segment_kind == "translation", :);
    elseif ismember('is_zero_length', rows.Properties.VariableNames)
        rows = rows(~rows.is_zero_length, :);
    else
        rows = rows(abs(rows.d) > 0, :);
    end
end


function thresholds = default_thresholds_local()
    thresholds = struct();
    thresholds.ok_abs_u_max = 0.05;
    thresholds.ok_relative_tan_error_max = 1e-3;
    thresholds.notice_abs_u_max = 0.10;
    thresholds.notice_relative_tan_error_max = 5e-3;
    thresholds.warning_abs_u_max = 0.20;
    thresholds.warning_relative_tan_error_max = 2e-2;
end


function T = thresholds_table_local(thresholds)
    names = string(fieldnames(thresholds));
    values = zeros(numel(names), 1);
    for k = 1:numel(names)
        values(k) = thresholds.(char(names(k)));
    end
    T = table(names, values, 'VariableNames', {'threshold', 'value'});
end


function fieldId = field_index_local(bundleSetRow, fallback)
    fieldId = fallback;
    if isfield(bundleSetRow, 'field_index') && ...
            isfinite(bundleSetRow.field_index)
        fieldId = bundleSetRow.field_index;
    end
end


function mode = sampling_mode_local(rayTable, rowIndex)
    mode = "";
    if istable(rayTable) && ismember('sampling_mode', rayTable.Properties.VariableNames) && ...
            height(rayTable) >= rowIndex
        mode = string(rayTable.sampling_mode(rowIndex));
    end
end


function value = max_or_nan_local(values)
    values = double(values(:));
    values = values(isfinite(values));
    if isempty(values)
        value = NaN;
    else
        value = max(values);
    end
end


function value = signed_max_abs_local(values)
    values = double(values(:));
    values = values(isfinite(values));
    if isempty(values)
        value = NaN;
    else
        [~, idx] = max(abs(values));
        value = values(idx);
    end
end


function note = worst_location_local(segRows, evtRows)
    note = "";
    if ~isempty(evtRows)
        evtScores = severity_local(evtRows.warning_level);
        [score, idx] = max(evtScores);
        if score > 0
            note = sprintf('event %d element %s (%s)', ...
                evtRows.event_index(idx), evtRows.element_id(idx), ...
                evtRows.type(idx));
            return
        end
    end
    if ~isempty(segRows)
        segScores = severity_local(segRows.warning_level);
        [score, idx] = max(segScores);
        if score > 0
            note = sprintf('segment %d z=[%.6g, %.6g]', ...
                segRows.segment_index(idx), segRows.z_start(idx), ...
                segRows.z_end(idx));
        end
    end
end


function level = max_level_array_local(levels)
    levels = string(levels(:));
    score = max(severity_local(levels));
    names = ["ok"; "notice"; "warning"; "severe"];
    level = names(score + 1);
end


function score = severity_local(levels)
    levels = string(levels(:));
    score = zeros(numel(levels), 1);
    score(levels == "notice") = 1;
    score(levels == "warning") = 2;
    score(levels == "severe") = 3;
end
