function overlay = nparaxial_first_segment_penalty_overlay_yu( ...
    rayTableOrBundle, zObj, zFirst, tol)
%NPARAXIAL_FIRST_SEGMENT_PENALTY_OVERLAY_YU First-segment plot overlay data.
%
% The overlay compares paraxial y = y0 + d*u with the diagnostic exact-angle
% line y = y0 + d*tan(u) only from the object plane to the first element.

    if nargin < 4 || isempty(tol)
        tol = 1e-12;
    end
    if ~isscalar(zObj) || ~isfinite(zObj) || ...
            ~isscalar(zFirst) || ~isfinite(zFirst)
        error('zObj and zFirst must be finite scalars.');
    end
    if ~isscalar(tol) || ~isfinite(tol) || tol <= 0
        tol = 1e-12;
    end

    rays = collect_rays_local(rayTableOrBundle);
    n = height(rays);
    d = zFirst - zObj;

    rayName = strings(n, 1);
    fieldIndex = zeros(n, 1);
    y0 = zeros(n, 1);
    u0 = zeros(n, 1);
    uDeg = zeros(n, 1);
    zStart = repmat(zObj, n, 1);
    zEnd = repmat(zFirst, n, 1);
    yParStart = zeros(n, 1);
    yParEnd = zeros(n, 1);
    yExactStart = zeros(n, 1);
    yExactEnd = NaN(n, 1);
    deltaY = NaN(n, 1);
    validOverlay = false(n, 1);
    note = strings(n, 1);

    for k = 1:n
        rayName(k) = rays.ray_name(k);
        fieldIndex(k) = rays.field_index(k);
        y0(k) = rays.y0(k);
        u0(k) = rays.u0(k);
        uDeg(k) = u0(k)*180/pi;
        yParStart(k) = y0(k);
        yParEnd(k) = y0(k) + d*u0(k);
        yExactStart(k) = y0(k);

        if abs(d) <= tol
            yExactEnd(k) = yParEnd(k);
            deltaY(k) = 0;
            note(k) = "First-segment distance is zero; overlay skipped.";
            continue
        end

        t = tan(u0(k));
        if ~isfinite(t)
            note(k) = "tan(u0) is nonfinite; exact-angle overlay skipped.";
            continue
        end

        yExactEnd(k) = y0(k) + d*t;
        deltaY(k) = d*(t - u0(k));
        validOverlay(k) = true;
        note(k) = "Overlay valid.";
    end

    overlay = table;
    overlay.ray_name = rayName;
    overlay.field_index = fieldIndex;
    overlay.y0 = y0;
    overlay.u0 = u0;
    overlay.u_deg = uDeg;
    overlay.z_start = zStart;
    overlay.z_end = zEnd;
    overlay.y_paraxial_start = yParStart;
    overlay.y_paraxial_end = yParEnd;
    overlay.y_exact_start = yExactStart;
    overlay.y_exact_end = yExactEnd;
    overlay.delta_y_first_segment = deltaY;
    overlay.valid_overlay = validOverlay;
    overlay.note = note;
end


function rays = collect_rays_local(source)
    rays = table();
    if istable(source)
        rays = normalize_ray_table_local(source, 1);
        return
    end

    if isstruct(source)
        for q = 1:numel(source)
            fieldId = q;
            if isfield(source(q), 'field_index') && isfinite(source(q).field_index)
                fieldId = source(q).field_index;
            end
            if isfield(source(q), 'rays') && istable(source(q).rays)
                rays = [rays; normalize_ray_table_local(source(q).rays, fieldId)]; %#ok<AGROW>
            elseif isfield(source(q), 'bundle')
                bundle = source(q).bundle;
                for r = 1:numel(bundle)
                    row = table;
                    row.ray_name = string(bundle(r).name);
                    row.field_index = fieldId;
                    row.y0 = bundle(r).ray_in(2);
                    row.u0 = bundle(r).ray_in(3);
                    rays = [rays; row]; %#ok<AGROW>
                end
            end
        end
        return
    end

    error('rayTableOrBundle must be a ray table or traced bundleSet struct.');
end


function rays = normalize_ray_table_local(T, fieldId)
    required = ["y0", "u0"];
    names = string(T.Properties.VariableNames);
    for k = 1:numel(required)
        if ~ismember(required(k), names)
            error('Ray table must contain y0 and u0 columns.');
        end
    end

    n = height(T);
    rays = table;
    if ismember("ray_name", names)
        rays.ray_name = string(T.ray_name);
    elseif ismember("name", names)
        rays.ray_name = string(T.name);
    else
        rays.ray_name = "ray_" + string((1:n).');
    end
    if ismember("field_index", names)
        rays.field_index = double(T.field_index);
    else
        rays.field_index = repmat(double(fieldId), n, 1);
    end
    rays.y0 = double(T.y0);
    rays.u0 = double(T.u0);
end
