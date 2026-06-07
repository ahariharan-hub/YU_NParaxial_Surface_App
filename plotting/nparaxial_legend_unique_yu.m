function [uniqueHandles, uniqueNames] = nparaxial_legend_unique_yu( ...
    plotHandles, displayNames)
%NPARAXIAL_LEGEND_UNIQUE_YU Deduplicate ray-role legend entries.
%
% Preferred order is UMR, CR, LMR, Intermediate, Clipped ray. Unknown
% nonempty labels are appended in first-seen order.

    if nargin < 1 || isempty(plotHandles)
        uniqueHandles = gobjects(0, 1);
        uniqueNames = strings(0, 1);
        return
    end

    plotHandles = plotHandles(:);
    if nargin < 2 || isempty(displayNames)
        displayNames = display_names_from_handles_local(plotHandles);
    else
        displayNames = string(displayNames(:));
    end

    n = min(numel(plotHandles), numel(displayNames));
    plotHandles = plotHandles(1:n);
    displayNames = displayNames(1:n);

    keep = false(n, 1);
    normalizedNames = strings(n, 1);
    for k = 1:n
        if ~isgraphics(plotHandles(k))
            continue
        end
        normalizedNames(k) = normalize_display_name_local(displayNames(k));
        keep(k) = strlength(normalizedNames(k)) > 0;
    end

    plotHandles = plotHandles(keep);
    normalizedNames = normalizedNames(keep);
    if isempty(plotHandles)
        uniqueHandles = gobjects(0, 1);
        uniqueNames = strings(0, 1);
        return
    end

    preferredNames = ["UMR"; "CR"; "LMR"; "Intermediate"; "Clipped ray"];
    uniqueHandles = gobjects(0, 1);
    uniqueNames = strings(0, 1);
    used = false(numel(normalizedNames), 1);

    for k = 1:numel(preferredNames)
        idx = find(normalizedNames == preferredNames(k), 1, 'first');
        if ~isempty(idx)
            uniqueHandles(end+1, 1) = plotHandles(idx); %#ok<AGROW>
            uniqueNames(end+1, 1) = preferredNames(k); %#ok<AGROW>
            used(idx) = true;
        end
    end

    for k = 1:numel(normalizedNames)
        if used(k) || any(uniqueNames == normalizedNames(k))
            continue
        end
        uniqueHandles(end+1, 1) = plotHandles(k); %#ok<AGROW>
        uniqueNames(end+1, 1) = normalizedNames(k); %#ok<AGROW>
    end
end


function displayNames = display_names_from_handles_local(plotHandles)
    displayNames = strings(numel(plotHandles), 1);
    for k = 1:numel(plotHandles)
        if isgraphics(plotHandles(k)) && isprop(plotHandles(k), 'DisplayName')
            displayNames(k) = string(plotHandles(k).DisplayName);
        end
    end
end


function name = normalize_display_name_local(displayName)
    text = strtrim(string(displayName));
    textLower = lower(text);
    name = "";

    if strlength(text) == 0 || textLower == "data" || ...
            startsWith(textLower, "data")
        return
    end

    if textLower == "umr"
        name = "UMR";
    elseif textLower == "cr"
        name = "CR";
    elseif textLower == "lmr"
        name = "LMR";
    elseif textLower == "intermediate" || textLower == "intermediate ray"
        name = "Intermediate";
    elseif textLower == "clipped ray"
        name = "Clipped ray";
    else
        name = text;
    end
end
