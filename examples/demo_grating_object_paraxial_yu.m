function out = demo_grating_object_paraxial_yu(showFigure, verbose)
%DEMO_GRATING_OBJECT_PARAXIAL_YU Scriptable grating-object ray demo.
%
% This demo does not launch V1 or V2. The grating is treated only as an
% object-plane ray launch condition; rays are traced with the existing
% paraxial bundle tracer.

    if nargin < 1 || isempty(showFigure)
        showFigure = true;
    end
    if nargin < 2 || isempty(verbose)
        verbose = true;
    end

    rootFolder = fileparts(fileparts(mfilename('fullpath')));
    addpath(fullfile(rootFolder, 'core'));

    prescription = nparaxial_default_prescription_yu("two thin lenses");
    prescription = nparaxial_validate_prescription_yu(prescription);

    zObj = -120;
    yObj = 0;
    wavelengthUm = 0.193;
    periodUm = 0.500;
    orders = (-2:2).';
    incidentAngleDeg = 0;
    nIn = 1;
    nOut = 1;

    [rays, gratingInfo] = nparaxial_make_grating_order_rays_yu( ...
        zObj, yObj, wavelengthUm, periodUm, orders, ...
        incidentAngleDeg, nIn, nOut);

    img = nparaxial_solve_image_plane_yu(prescription, zObj, 1e-12);
    if isfield(img, 'trace_z_final') && isfinite(img.trace_z_final)
        zFinal = img.trace_z_final;
    elseif isfield(img, 'z_image') && isfinite(img.z_image)
        zFinal = img.z_image;
    else
        zFinal = max(prescription.z) + 200;
    end

    bundle = nparaxial_trace_bundle_yu(rays, prescription, zFinal);
    traceTable = trace_result_table_local(rays, bundle);

    if verbose
        fprintf('Grating object demo: requested orders=%d, propagating=%d\n', ...
            numel(orders), height(rays));
        disp(gratingInfo.order_table(:, [ ...
            "diffraction_order", "is_propagating", ...
            "theta_m_deg", "sin_theta_m"]));
        disp(traceTable);
    end

    fig = [];
    if showFigure
        fig = plot_grating_trace_local(prescription, rays, bundle, ...
            zObj, zFinal);
    end

    out = struct();
    out.prescription = prescription;
    out.rays = rays;
    out.info = gratingInfo;
    out.bundle = bundle;
    out.trace_table = traceTable;
    out.figure = fig;
end


function traceTable = trace_result_table_local(rays, bundle)
    nRays = numel(bundle);
    rayName = strings(nRays, 1);
    traced = false(nRays, 1);
    yFinal = NaN(nRays, 1);
    uFinal = NaN(nRays, 1);
    blockedAtZ = NaN(nRays, 1);
    blockedY = NaN(nRays, 1);

    for k = 1:nRays
        rayName(k) = string(bundle(k).name);
        traced(k) = logical(bundle(k).trc);
        yFinal(k) = bundle(k).yf;
        uFinal(k) = bundle(k).uf;
        blockedAtZ(k) = bundle(k).res.blocked_at_z;
        blockedY(k) = bundle(k).res.blocked_y;
    end

    traceTable = table( ...
        rayName, ...
        rays.diffraction_order, ...
        rays.u0, ...
        rays.theta_m_deg, ...
        traced, ...
        yFinal, ...
        uFinal, ...
        blockedAtZ, ...
        blockedY, ...
        'VariableNames', { ...
        'ray_name', ...
        'diffraction_order', ...
        'u0', ...
        'theta_m_deg', ...
        'traced', ...
        'y_final', ...
        'u_final', ...
        'blocked_at_z', ...
        'blocked_y'});
end


function fig = plot_grating_trace_local(prescription, rays, bundle, zObj, zFinal)
    fig = figure('Name', ...
        'Paraxial grating object through two-thin-lens system');
    ax = axes(fig);
    hold(ax, 'on');
    grid(ax, 'on');
    box(ax, 'on');
    xlabel(ax, 'z [mm]');
    ylabel(ax, 'y [mm]');
    title(ax, '2D paraxial grating object: diffraction-order rays');

    plot(ax, [zObj, zFinal], [0, 0], ...
        'k-', 'LineWidth', 0.75, 'DisplayName', 'Optical axis');
    draw_elements_local(ax, prescription);
    xline(ax, zObj, ':', 'Object/grating', 'HandleVisibility', 'off');
    xline(ax, zFinal, ':', 'Trace final', 'HandleVisibility', 'off');

    allY = zeros(0, 1);
    colors = lines(max(1, numel(bundle)));
    for k = 1:numel(bundle)
        res = bundle(k).res;
        for s = 1:numel(res.seg_z)
            zSeg = res.seg_z{s};
            ySeg = res.seg_y{s};
            if numel(zSeg) < 2 || numel(ySeg) < 2
                continue
            end
            displayName = '';
            if s == 1
                displayName = sprintf('m = %+d', rays.diffraction_order(k));
            end
            plot(ax, zSeg, ySeg, ...
                'Color', colors(k, :), ...
                'LineWidth', 1.2, ...
                'DisplayName', displayName);
            allY = [allY; ySeg(:)]; %#ok<AGROW>
        end
        if ~res.trc && isfinite(res.blocked_at_z)
            plot(ax, res.blocked_at_z, res.blocked_y, 'x', ...
                'Color', colors(k, :), ...
                'MarkerSize', 8, ...
                'LineWidth', 1.5, ...
                'DisplayName', sprintf('m = %+d clipped', ...
                rays.diffraction_order(k)));
            allY = [allY; res.blocked_y]; %#ok<AGROW>
        end
    end

    if ~isempty(allY) && any(isfinite(allY))
        yMax = max(abs(allY(isfinite(allY))));
        ylim(ax, 1.15 * max(yMax, 1) * [-1, 1]);
    end
    legend(ax, 'Location', 'best');
end


function draw_elements_local(ax, prescription)
    for k = 1:height(prescription)
        z = prescription.z(k);
        typeName = string(prescription.type(k));
        aperture = prescription.aperture_radius(k);
        if isfinite(aperture)
            ySpan = [-aperture, aperture];
        else
            ySpan = [-20, 20];
        end

        switch typeName
            case "thinlens"
                lineStyle = '-';
                lineWidth = 1.5;
                color = [0 0 0];
            case "stop"
                lineStyle = '--';
                lineWidth = 1.2;
                color = [0 0 0];
            otherwise
                lineStyle = ':';
                lineWidth = 1.0;
                color = [0.4 0.4 0.4];
        end

        plot(ax, [z, z], ySpan, ...
            'Color', color, ...
            'LineStyle', lineStyle, ...
            'LineWidth', lineWidth, ...
            'HandleVisibility', 'off');
        text(ax, z, ySpan(2), " " + prescription.element_id(k), ...
            'VerticalAlignment', 'bottom', ...
            'HandleVisibility', 'off');
    end
end
