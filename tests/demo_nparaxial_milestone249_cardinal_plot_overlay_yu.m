function results = demo_nparaxial_milestone249_cardinal_plot_overlay_yu()
%DEMO_NPARAXIAL_MILESTONE249_CARDINAL_PLOT_OVERLAY_YU Overlay checks.

    testFolder = fileparts(mfilename('fullpath'));
    rootFolder = fileparts(testFolder);
    addpath(rootFolder);
    addpath(fullfile(rootFolder, 'core'));

    numChecks = 0;

    p = nparaxial_default_prescription_yu("single thin lens");
    card = nparaxial_cardinal_points_yu(p, 0, 0);
    finiteFields = ["z_F"; "z_Fp"; "z_H1"; "z_H2"; "z_N1"; "z_N2"];
    assert(card.is_finite_power, ...
        'Single thin lens should provide finite-power cardinal points.');
    for k = 1:numel(finiteFields)
        fieldName = char(finiteFields(k));
        assert(isfinite(card.(fieldName)), ...
            'Finite-power cardinal field %s should be finite.', ...
            fieldName);
    end
    numChecks = numChecks + 1;

    fig = figure('Visible', 'off');
    cleanupFig = onCleanup(@() close(fig)); %#ok<NASGU>
    ax = axes(fig);
    hold(ax, 'on');
    yLimits = [-12, 12];
    zLimits = [-100, 100];
    ylim(ax, yLimits);
    xlim(ax, zLimits);
    plot(ax, [-20, 20], [8, 4], ...
        'Color', [0 0.4470 0.7410], 'DisplayName', 'UMR');
    plot(ax, [-20, 20], [0, 0], ...
        'Color', [0.8500 0.0000 0.0000], 'DisplayName', 'CR');
    plot(ax, [-20, 20], [-8, -4], ...
        'Color', [0.0000 0.6000 0.0000], 'DisplayName', 'LMR');

    hCardinal = nparaxial_plot_cardinal_points_yu( ...
        ax, card, yLimits, zLimits);
    assert(~isempty(hCardinal), ...
        'Finite-power cardinal overlay should create marker handles.');
    assert(any(isgraphics(hCardinal, 'line')), ...
        'Finite-power cardinal overlay should create vertical lines.');
    numChecks = numChecks + 1;

    handleVisibility = string(get(hCardinal, 'HandleVisibility'));
    assert(all(handleVisibility == "off"), ...
        'All cardinal marker handles should be hidden from legends.');
    numChecks = numChecks + 1;

    textHandles = findall(ax, 'Type', 'text');
    textLabels = string(get(textHandles, 'String'));
    expectedLabels = ["F"; "H"; "N"; "N'"; "H'"; "F'"];
    for k = 1:numel(expectedLabels)
        assert(any(textLabels == expectedLabels(k)), ...
            'Cardinal label %s should be present as direct text.', ...
            expectedLabels(k));
    end
    numChecks = numChecks + 1;

    lgd = legend(ax, 'show');
    legendNames = string(lgd.String(:));
    assert(all(~ismember(expectedLabels, legendNames)), ...
        'Cardinal point labels should not appear in the Ray Diagram legend.');
    assert(all(ismember(["UMR"; "CR"; "LMR"], legendNames)), ...
        'Ray role labels should remain available to the legend.');
    numChecks = numChecks + 1;

    translationPreset = nparaxial_default_prescription_yu( ...
        "Homogeneous translation / free-space propagation");
    translationCard = nparaxial_cardinal_points_yu( ...
        translationPreset, 0, 100);
    assert(~translationCard.is_finite_power, ...
        'Translation preset should be afocal/zero-power for cardinal points.');
    hTranslation = nparaxial_plot_cardinal_points_yu( ...
        ax, translationCard, yLimits, zLimits);
    assert(isempty(hTranslation), ...
        'Afocal/zero-power systems should not plot cardinal markers.');
    numChecks = numChecks + 1;

    hold(ax, 'off');

    results = struct();
    results.case_name = "milestone249_cardinal_plot_overlay";
    results.num_checks = numChecks;
    results.cardinal_marker_handles = numel(hCardinal);
end
