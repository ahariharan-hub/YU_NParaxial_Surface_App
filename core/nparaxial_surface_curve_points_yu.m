function [zCurve, yCurve, info] = nparaxial_surface_curve_points_yu( ...
    zVertex, R, apertureRadius, yFallback, nPts, tol)
%NPARAXIAL_SURFACE_CURVE_POINTS_YU Plot points for a spherical surface.
%
% This helper is graphical only. It uses the app's radius convention:
% R > 0 places the center of curvature at larger z than the vertex, and
% R < 0 places the center at smaller z.

    if nargin < 4 || isempty(yFallback)
        yFallback = 1;
    end
    if nargin < 5 || isempty(nPts)
        nPts = 121;
    end
    if nargin < 6 || isempty(tol)
        tol = 1e-12;
    end

    if ~isscalar(zVertex) || ~isfinite(zVertex)
        error('zVertex must be a finite scalar.');
    end
    if ~isscalar(R) || isnan(R) || R == 0
        error('R must be nonzero, finite, or Inf.');
    end
    if ~isscalar(apertureRadius) || isnan(apertureRadius) || apertureRadius <= 0
        error('apertureRadius must be positive finite or Inf.');
    end
    if ~isscalar(yFallback) || ~isfinite(yFallback) || yFallback <= 0
        yFallback = 1;
    end
    if ~isscalar(nPts) || ~isfinite(nPts)
        nPts = 121;
    end
    nPts = max(5, round(nPts));
    if ~isscalar(tol) || ~isfinite(tol) || tol <= 0
        tol = 1e-12;
    end

    usedFallback = ~isfinite(apertureRadius);
    invalidCurve = false;
    note = "";

    if isinf(R)
        yMax = y_plot_max_local(apertureRadius, yFallback);
        yCurve = linspace(-yMax, yMax, nPts).';
        zCurve = repmat(double(zVertex), nPts, 1);
        info = struct( ...
            'is_finite_surface', false, ...
            'used_fallback_height', usedFallback, ...
            'y_plot_max', yMax, ...
            'invalid_curve_flag', false, ...
            'note', "Plane surface: use a vertical line.");
        return
    end

    radiusAbs = abs(R);
    yMax = y_plot_max_local(apertureRadius, yFallback);
    if yMax > radiusAbs
        invalidCurve = true;
        note = "Requested plotting height exceeds spherical radius; curve clipped to valid branch.";
        yMax = (1 - sqrt(tol))*radiusAbs;
    end
    if yMax <= 0 || ~isfinite(yMax)
        yMax = 0.5*radiusAbs;
        usedFallback = true;
    end

    yCurve = linspace(-yMax, yMax, nPts).';
    sag = R - sign(R)*sqrt(max(R^2 - yCurve.^2, 0));
    zCurve = zVertex + sag;

    if strlength(note) == 0
        if usedFallback
            note = "Finite spherical surface plotted with fallback visual height.";
        else
            note = "Finite spherical surface plotted over finite aperture radius.";
        end
    end

    info = struct( ...
        'is_finite_surface', true, ...
        'used_fallback_height', usedFallback, ...
        'y_plot_max', yMax, ...
        'invalid_curve_flag', invalidCurve, ...
        'note', note);
end


function yMax = y_plot_max_local(apertureRadius, yFallback)
    if isfinite(apertureRadius)
        yMax = abs(apertureRadius);
    else
        yMax = abs(yFallback);
    end
    if ~isfinite(yMax) || yMax <= 0
        yMax = 1;
    end
end
