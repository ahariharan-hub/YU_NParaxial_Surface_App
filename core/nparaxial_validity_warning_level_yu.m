function levels = nparaxial_validity_warning_level_yu( ...
    u, relative_tan_error, tir_flag, invalid_flag)
%NPARAXIAL_VALIDITY_WARNING_LEVEL_YU Central paraxial-validity thresholds.
%
% Returned levels are "ok", "notice", "warning", or "severe".

    if nargin < 2 || isempty(relative_tan_error)
        metrics = nparaxial_angle_validity_metrics_yu(u);
        relative_tan_error = metrics.relative_tan_error;
    end
    if nargin < 3 || isempty(tir_flag)
        tir_flag = false;
    end
    if nargin < 4 || isempty(invalid_flag)
        invalid_flag = false;
    end

    u = double(u(:));
    relative_tan_error = expand_logical_or_double_local( ...
        relative_tan_error, numel(u));
    tir_flag = logical(expand_logical_or_double_local(tir_flag, numel(u)));
    invalid_flag = logical(expand_logical_or_double_local( ...
        invalid_flag, numel(u)));

    levels = strings(numel(u), 1);
    for k = 1:numel(u)
        absU = abs(u(k));
        rel = relative_tan_error(k);
        tanNearSingular = isfinite(u(k)) && abs(cos(u(k))) < 1e-9;

        if invalid_flag(k) || tir_flag(k) || ~isfinite(absU) || ...
                ~isfinite(rel) || tanNearSingular
            levels(k) = "severe";
        elseif absU <= 0.05 && rel < 1e-3
            levels(k) = "ok";
        elseif absU <= 0.10 || rel < 5e-3
            levels(k) = "notice";
        elseif absU <= 0.20 || rel < 2e-2
            levels(k) = "warning";
        else
            levels(k) = "severe";
        end
    end
end


function values = expand_logical_or_double_local(values, n)
    values = values(:);
    if isempty(values)
        values = zeros(n, 1);
    elseif isscalar(values) && n > 1
        values = repmat(values, n, 1);
    end
    if numel(values) ~= n
        error('Threshold inputs must be scalar or match numel(u).');
    end
    values = double(values);
end
