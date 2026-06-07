function caseDef = nparaxial_get_default_case_yu(caseName)
%NPARAXIAL_GET_DEFAULT_CASE_YU Return one structured default case.

    if nargin < 1 || strlength(string(caseName)) == 0
        caseName = "basic_single_lens_m_minus_0p5";
    end

    cases = nparaxial_default_case_library_yu();
    wanted = normalize_key_local(caseName);
    keys = strings(numel(cases), 1);

    for k = 1:numel(cases)
        aliases = case_aliases_local(cases(k));
        match = normalize_key_local(aliases);
        if any(match == wanted)
            caseDef = cases(k);
            return
        end
        keys(k) = cases(k).display_name;
    end

    error('Unknown default case "%s". Valid cases include: %s.', ...
        string(caseName), strjoin(cellstr(keys), ', '));
end


function aliases = case_aliases_local(caseDef)
    aliases = [
        caseDef.key
        caseDef.name
        caseDef.display_name
        caseDef.family + " " + caseDef.name
        ];

    switch caseDef.key
        case "basic_single_lens_m_minus_0p5"
            aliases = [aliases; ...
                "default"; ...
                "basic default"; ...
                "single lens finite conjugate"; ...
                "single lens finite conjugate m -0.5"];

        case "debug_legacy_two_thin_lens"
            aliases = [aliases; ...
                "two thin lenses"; ...
                "legacy two thin lenses"; ...
                "legacy two-thin-lens"; ...
                "debug legacy two-thin-lens"];

        case "debug_stop_clipping_demo"
            aliases = [aliases; ...
                "stop clipping demo"; ...
                "debug stop clipping demo"];

        case "debug_homogeneous_translation"
            aliases = [aliases; ...
                "homogeneous translation / free-space propagation"; ...
                "homogeneous translation"; ...
                "free-space propagation"];

        case "thick_biconvex"
            aliases = [aliases; ...
                "two-surface thick lens"; ...
                "two surface thick lens"];
    end
end


function key = normalize_key_local(value)
    key = lower(strtrim(string(value)));
    key = regexprep(key, '[^a-z0-9]', '');
end
