function sweep = nparaxial_validity_field_sweep_yu( ...
    prescription, zObj, fieldHeights, rayFanSettings, validitySettings, tol)
%NPARAXIAL_VALIDITY_FIELD_SWEEP_YU Sweep paraxial-validity metrics by field.
%
% This collector reuses the existing ray-fan, paraxial trace, and
% paraxial-validity helpers. It is diagnostic-only and does not alter the
% main trace engine, aperture clipping, matrices, or exact-hit diagnostics.

    if nargin < 4 || isempty(rayFanSettings)
        rayFanSettings = struct();
    end
    if nargin < 5 || isempty(validitySettings)
        validitySettings = struct();
    end
    if nargin < 6 || isempty(tol)
        tol = 1e-12;
    end

    prescription = nparaxial_validate_prescription_yu(prescription);
    validate_inputs_local(zObj, fieldHeights, tol);

    fieldHeights = double(fieldHeights(:));
    settings = normalize_ray_fan_settings_local(rayFanSettings);
    zFinal = resolve_z_final_local(prescription, zObj, validitySettings);

    nFields = numel(fieldHeights);
    detail = repmat(struct( ...
        'field_index', [], ...
        'y_field', [], ...
        'rays', table(), ...
        'bundle', [], ...
        'validity', [], ...
        'ray_fan_info', []), nFields, 1);

    rows = cell(nFields, 1);
    for k = 1:nFields
        yField = fieldHeights(k);
        rows{k} = make_empty_row_local(k, yField, settings, ...
            "Field sweep row initialized.");
        try
            [rays, fanInfo] = make_rays_local( ...
                prescription, zObj, yField, settings, zFinal, tol);
            detail(k).field_index = k;
            detail(k).y_field = yField;
            detail(k).rays = rays;
            detail(k).ray_fan_info = fanInfo;

            rows{k}.ray_fan_mode = fanInfo.sampling_mode;
            rows{k}.n_rays_requested = settings.n_rays;
            rows{k}.status_text = fanInfo.status_text;

            if fanInfo.fully_vignetted || height(rays) == 0
                rows{k}.n_rays_valid = 0;
                rows{k}.n_rays_blocked = 0;
                rows{k}.status_text = fanInfo.status_text;
                continue
            end

            bundle = nparaxial_trace_bundle_yu(rays, prescription, zFinal);
            detail(k).bundle = bundle;
            rows{k}.n_rays_valid = sum([bundle.trc]);
            rows{k}.n_rays_blocked = numel(bundle) - rows{k}.n_rays_valid;

            bundleSet = struct();
            bundleSet.field_index = k;
            bundleSet.y_obj = yField;
            bundleSet.rays = rays;
            bundleSet.bundle = bundle;

            validity = nparaxial_paraxial_validity_yu( ...
                bundleSet, prescription, [], tol);
            detail(k).validity = validity;
            rows{k} = reduce_validity_local(rows{k}, validity, fanInfo);
        catch ME
            rows{k}.status_text = "Field sweep error: " + string(ME.message);
        end
    end

    sweep = struct();
    sweep.sweep_summary_table = vertcat(rows{:});
    sweep.sweep_detail = detail;
    sweep.status_text = sprintf( ...
        'Paraxial validity field sweep evaluated %d field point(s).', nFields);
    sweep.z_obj = zObj;
    sweep.z_final = zFinal;
    sweep.ray_fan_settings = settings;
end


function validate_inputs_local(zObj, fieldHeights, tol)
    if ~isscalar(zObj) || ~isfinite(zObj)
        error('zObj must be a finite scalar.');
    end
    if isempty(fieldHeights) || any(~isfinite(double(fieldHeights(:))))
        error('fieldHeights must contain finite values.');
    end
    if ~isscalar(tol) || ~isfinite(tol) || tol <= 0
        error('tol must be a positive finite scalar.');
    end
end


function settings = normalize_ray_fan_settings_local(rayFanSettings)
    settings = struct();
    settings.mode = get_field_local( ...
        rayFanSettings, 'mode', "Manual fixed-angle fan");
    settings.n_rays = get_field_local(rayFanSettings, 'n_rays', 9);
    settings.manual_u_max = get_field_local( ...
        rayFanSettings, 'manual_u_max', 0.04);

    settings.mode = string(settings.mode);
    settings.n_rays = round(double(settings.n_rays));
    settings.manual_u_max = double(settings.manual_u_max);
    if settings.n_rays < 3
        error('rayFanSettings.n_rays must be at least 3.');
    end
    if mod(settings.n_rays, 2) == 0
        settings.n_rays = settings.n_rays + 1;
    end
    if ~isfinite(settings.manual_u_max) || settings.manual_u_max <= 0
        error('rayFanSettings.manual_u_max must be positive finite.');
    end
end


function value = get_field_local(S, name, defaultValue)
    value = defaultValue;
    if isstruct(S) && isfield(S, name) && ~isempty(S.(name))
        value = S.(name);
    end
end


function zFinal = resolve_z_final_local(prescription, zObj, validitySettings)
    if isstruct(validitySettings) && isfield(validitySettings, 'z_final') && ...
            ~isempty(validitySettings.z_final)
        zFinal = double(validitySettings.z_final);
    else
        img = nparaxial_solve_image_plane_yu(prescription, zObj);
        zFinal = img.z_img;
    end
    if ~isscalar(zFinal) || ~isfinite(zFinal) || zFinal < zObj
        error('validitySettings.z_final must be finite and after zObj.');
    end
end


function [rays, fanInfo] = make_rays_local( ...
    prescription, zObj, yField, settings, zFinal, tol)

    if settings.mode == "Aperture-limited admitted cone"
        rays = nparaxial_make_aperture_limited_rays_yu( ...
            prescription, zObj, yField, settings.n_rays, ...
            settings.manual_u_max, tol, zFinal);
    else
        rays = nparaxial_make_manual_fan_rays_yu( ...
            zObj, yField, settings.n_rays, settings.manual_u_max);
    end
    fanInfo = rays.Properties.UserData;
end


function row = make_empty_row_local(fieldIndex, yField, settings, statusText)
    row = table;
    row.field_index = double(fieldIndex);
    row.y_field = double(yField);
    row.ray_fan_mode = string(settings.mode);
    row.n_rays_requested = double(settings.n_rays);
    row.n_rays_valid = 0;
    row.n_rays_blocked = 0;
    row.worst_angle_deg = NaN;
    row.worst_translation_delta_y = NaN;
    row.max_abs_translation_delta_y = NaN;
    row.worst_plane_refraction_delta_u = NaN;
    row.worst_surface_vertex_delta_u = NaN;
    row.worst_true_intersection_delta_u = NaN;
    row.max_thinlens_deflection = NaN;
    row.tir_count = 0;
    row.invalid_normal_count = 0;
    row.no_intersection_count = 0;
    row.ambiguous_intersection_count = 0;
    row.notice_count = 0;
    row.warning_count = 0;
    row.severe_count = 0;
    row.worst_warning_level = "ok";
    row.status_text = string(statusText);
end


function row = reduce_validity_local(row, validity, fanInfo)
    summary = validity.summary_table;
    events = validity.event_table;

    row.status_text = fanInfo.status_text;
    if isempty(summary)
        return
    end

    row.worst_angle_deg = max_or_nan_local(summary.worst_angle_deg);
    row.worst_translation_delta_y = signed_max_abs_local( ...
        summary.worst_translation_delta_y);
    row.max_abs_translation_delta_y = max_abs_or_nan_local( ...
        summary.worst_translation_delta_y);
    row.worst_plane_refraction_delta_u = signed_max_abs_local( ...
        summary.worst_plane_refraction_delta_u);
    row.worst_surface_vertex_delta_u = signed_max_abs_local( ...
        summary.worst_surface_vertex_delta_u);
    row.worst_true_intersection_delta_u = signed_max_abs_local( ...
        summary.worst_surface_true_intersection_delta_u);
    row.max_thinlens_deflection = max_or_nan_local( ...
        summary.max_thinlens_deflection);
    row.tir_count = sum(summary.tir_count);
    row.notice_count = sum(summary.notice_count);
    row.warning_count = sum(summary.warning_count);
    row.severe_count = sum(summary.severe_count);
    row.worst_warning_level = max_warning_level_local( ...
        summary.worst_warning_level);

    if ~isempty(events)
        row.invalid_normal_count = nparaxial_count_row_union_flags_yu( ...
            events, ["invalid_surface_normal_flag", "invalid_hit_normal_flag"]);
        row.no_intersection_count = count_flag_local( ...
            events, "no_intersection_flag");
        row.ambiguous_intersection_count = count_flag_local( ...
            events, "surface_intersection_ambiguous_flag");
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


function value = max_abs_or_nan_local(values)
    values = double(values(:));
    values = values(isfinite(values));
    if isempty(values)
        value = NaN;
    else
        value = max(abs(values));
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


function count = count_flag_local(T, names)
    names = string(names(:));
    count = 0;
    tableNames = string(T.Properties.VariableNames);
    for k = 1:numel(names)
        if ismember(names(k), tableNames)
            count = count + sum(logical(T.(names(k))));
        end
    end
end


function level = max_warning_level_local(levels)
    scores = severity_local(levels);
    names = ["ok"; "notice"; "warning"; "severe"];
    if isempty(scores)
        level = "ok";
    else
        level = names(max(scores) + 1);
    end
end


function score = severity_local(levels)
    levels = string(levels(:));
    score = zeros(numel(levels), 1);
    score(levels == "notice") = 1;
    score(levels == "warning") = 2;
    score(levels == "severe") = 3;
end
