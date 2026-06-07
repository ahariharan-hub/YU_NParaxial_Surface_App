function nDeleted = nparaxial_clear_cardinal_points_yu(ax)
%NPARAXIAL_CLEAR_CARDINAL_POINTS_YU Delete owned cardinal overlay objects.

    nDeleted = 0;
    if nargin < 1 || isempty(ax) || ~isgraphics(ax)
        return
    end

    h = findall(ax, 'Tag', 'nparaxial_cardinal_overlay');
    if isempty(h)
        return
    end

    nDeleted = numel(h);
    delete(h(isgraphics(h)));
end
