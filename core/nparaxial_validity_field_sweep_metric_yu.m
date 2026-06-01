function [values, statusText] = nparaxial_validity_field_sweep_metric_yu( ...
    sweepSummaryTable, metricName)
%NPARAXIAL_VALIDITY_FIELD_SWEEP_METRIC_YU Extract one sweep metric safely.

    if ~istable(sweepSummaryTable)
        error('sweepSummaryTable must be a table.');
    end
    metricName = string(metricName);
    n = height(sweepSummaryTable);

    if isempty(sweepSummaryTable) || ...
            ~ismember(metricName, string(sweepSummaryTable.Properties.VariableNames))
        values = NaN(n, 1);
        statusText = "Selected field-sweep metric is unavailable for this system.";
        return
    end

    values = double(sweepSummaryTable.(metricName));
    statusText = "Metric available.";
end
