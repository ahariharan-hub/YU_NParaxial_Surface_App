function varargout = nparaxial_perf_timer_yu(action, varargin)
%NPARAXIAL_PERF_TIMER_YU Lightweight named-section timing helper.
%
% Usage examples:
%   timer = nparaxial_perf_timer_yu("new", true);
%   timer = nparaxial_perf_timer_yu("start", timer, "ray tracing");
%   timer = nparaxial_perf_timer_yu("stop", timer, "ray tracing");
%   T = nparaxial_perf_timer_yu("summary", timer);

    if nargin < 1 || strlength(string(action)) == 0
        action = "new";
    end
    action = lower(strtrim(string(action)));

    switch action
        case "new"
            enabled = true;
            if ~isempty(varargin)
                enabled = logical(varargin{1});
            end
            varargout{1} = new_timer_local(enabled);

        case "start"
            timer = normalize_timer_local(varargin{1});
            section = string(varargin{2});
            if timer.enabled
                key = section_key_local(section);
                timer.active.(key) = tic;
                timer.active_labels.(key) = section;
            end
            varargout{1} = timer;

        case "stop"
            timer = normalize_timer_local(varargin{1});
            section = string(varargin{2});
            if timer.enabled
                key = section_key_local(section);
                if isfield(timer.active, key)
                    elapsed = toc(timer.active.(key));
                    label = section;
                    if isfield(timer.active_labels, key)
                        label = timer.active_labels.(key);
                    end
                    timer = append_elapsed_local(timer, label, elapsed);
                    timer.active = rmfield(timer.active, key);
                    if isfield(timer.active_labels, key)
                        timer.active_labels = rmfield(timer.active_labels, key);
                    end
                end
            end
            varargout{1} = timer;

        case {"add", "add_elapsed"}
            timer = normalize_timer_local(varargin{1});
            section = string(varargin{2});
            elapsed = double(varargin{3});
            if timer.enabled
                timer = append_elapsed_local(timer, section, elapsed);
            end
            varargout{1} = timer;

        case "merge"
            timer = normalize_timer_local(varargin{1});
            other = normalize_timer_local(varargin{2});
            if timer.enabled && ~isempty(other.log)
                for k = 1:height(other.log)
                    timer = append_elapsed_local( ...
                        timer, other.log.section(k), other.log.elapsed_s(k));
                end
            end
            varargout{1} = timer;

        case {"table", "log"}
            timer = normalize_timer_local(varargin{1});
            varargout{1} = timer.log;

        case "summary"
            timer = normalize_timer_local(varargin{1});
            varargout{1} = summary_table_local(timer.log);

        case "format"
            timer = normalize_timer_local(varargin{1});
            nTop = 8;
            if numel(varargin) >= 2
                nTop = max(0, round(double(varargin{2})));
            end
            varargout{1} = format_summary_local(timer, nTop);

        otherwise
            error('Unsupported performance timer action "%s".', action);
    end
end


function timer = new_timer_local(enabled)
    timer = struct();
    timer.enabled = logical(enabled);
    timer.log = empty_log_table_local();
    timer.active = struct();
    timer.active_labels = struct();
end


function timer = normalize_timer_local(timer)
    if nargin < 1 || isempty(timer) || ~isstruct(timer)
        timer = new_timer_local(false);
        return
    end
    if ~isfield(timer, 'enabled')
        timer.enabled = true;
    else
        timer.enabled = logical(timer.enabled);
    end
    if ~isfield(timer, 'log') || ~istable(timer.log)
        timer.log = empty_log_table_local();
    end
    if ~isfield(timer, 'active') || ~isstruct(timer.active)
        timer.active = struct();
    end
    if ~isfield(timer, 'active_labels') || ~isstruct(timer.active_labels)
        timer.active_labels = struct();
    end
end


function timer = append_elapsed_local(timer, section, elapsed)
    elapsed = double(elapsed);
    if isempty(elapsed) || ~isfinite(elapsed)
        elapsed = NaN;
    end
    call_index = height(timer.log) + 1;
    timer.log(end+1, :) = {string(section), elapsed, call_index}; %#ok<AGROW>
end


function T = empty_log_table_local()
    T = table( ...
        strings(0, 1), ...
        zeros(0, 1), ...
        zeros(0, 1), ...
        'VariableNames', {'section', 'elapsed_s', 'call_index'});
end


function T = summary_table_local(logTable)
    if ~istable(logTable) || isempty(logTable)
        T = table( ...
            strings(0, 1), ...
            zeros(0, 1), ...
            zeros(0, 1), ...
            zeros(0, 1), ...
            zeros(0, 1), ...
            zeros(0, 1), ...
            'VariableNames', {'section', 'call_count', ...
            'total_elapsed_s', 'mean_elapsed_s', ...
            'max_elapsed_s', 'last_elapsed_s'});
        return
    end

    sections = unique(logTable.section, 'stable');
    n = numel(sections);
    callCount = zeros(n, 1);
    totalElapsed = zeros(n, 1);
    meanElapsed = zeros(n, 1);
    maxElapsed = zeros(n, 1);
    lastElapsed = zeros(n, 1);

    for k = 1:n
        mask = logTable.section == sections(k);
        values = logTable.elapsed_s(mask);
        finiteValues = values(isfinite(values));
        callCount(k) = numel(values);
        if isempty(finiteValues)
            totalElapsed(k) = NaN;
            meanElapsed(k) = NaN;
            maxElapsed(k) = NaN;
        else
            totalElapsed(k) = sum(finiteValues);
            meanElapsed(k) = mean(finiteValues);
            maxElapsed(k) = max(finiteValues);
        end
        lastElapsed(k) = values(end);
    end

    T = table(sections, callCount, totalElapsed, meanElapsed, ...
        maxElapsed, lastElapsed, ...
        'VariableNames', {'section', 'call_count', 'total_elapsed_s', ...
        'mean_elapsed_s', 'max_elapsed_s', 'last_elapsed_s'});
    [~, idx] = sort(T.total_elapsed_s, 'descend');
    T = T(idx, :);
end


function lines = format_summary_local(timer, nTop)
    summary = summary_table_local(timer.log);
    lines = strings(0, 1);
    if ~timer.enabled
        lines = "Performance timing is disabled.";
        return
    end
    if isempty(summary)
        lines = "No performance timings have been recorded.";
        return
    end

    lines(end+1, 1) = "Performance timings";
    lines(end+1, 1) = "-------------------";
    n = min(nTop, height(summary));
    for k = 1:n
        lines(end+1, 1) = sprintf( ...
            '%s: total %.6g s, calls %d, mean %.6g s', ...
            summary.section(k), summary.total_elapsed_s(k), ...
            summary.call_count(k), summary.mean_elapsed_s(k)); %#ok<AGROW>
    end
end


function key = section_key_local(section)
    key = matlab.lang.makeValidName(char("s_" + string(section)));
    if strlength(string(key)) == 0
        key = 's_section';
    end
end
