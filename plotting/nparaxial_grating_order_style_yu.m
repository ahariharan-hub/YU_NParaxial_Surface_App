function styles = nparaxial_grating_order_style_yu(rayInfo, clipped, orderSet)
%NPARAXIAL_GRATING_ORDER_STYLE_YU Return stable plotting styles by order.

    if nargin < 2 || isempty(clipped)
        clipped = false;
    end
    if nargin < 3
        orderSet = [];
    end

    orders = diffraction_orders_local(rayInfo);
    n = numel(orders);
    clipped = normalize_clipped_local(clipped, n);
    if isempty(orderSet)
        orderSet = orders;
    end
    orderSet = round(double(orderSet(:)));
    orderSet = orderSet(isfinite(orderSet));
    if isempty(orderSet)
        orderSet = 0;
    end

    nonzeroSet = orderSet(orderSet ~= 0);
    if isempty(nonzeroSet)
        nonzeroSet = orders(orders ~= 0);
    end
    if isempty(nonzeroSet)
        nonzeroSet = 1;
    end
    M = max(abs(nonzeroSet));
    M = max(0, round(double(M)));
    C = centered_order_colormap_local(M);

    color = zeros(n, 3);
    line_style = repmat("-", n, 1);
    display_name = strings(n, 1);
    marker = repmat("none", n, 1);
    line_width = repmat(1.25, n, 1);

    for k = 1:n
        m = round(double(orders(k)));
        if m == 0
            color(k, :) = [0 0 0];
            line_width(k) = 1.9;
        else
            if m < 0
                idx = m + M + 1;
            else
                idx = M + m;
            end
            idx = min(max(idx, 1), size(C, 1));
            color(k, :) = C(idx, :);
        end
        if clipped(k)
            line_style(k) = "--";
            marker(k) = "x";
            line_width(k) = line_width(k) + 0.2;
        end
        display_name(k) = order_label_local(m);
    end

    styles = table(color, line_style, display_name, marker, line_width);
end


function orders = diffraction_orders_local(rayInfo)
    if istable(rayInfo)
        names = string(rayInfo.Properties.VariableNames);
        if ~ismember("diffraction_order", names)
            error('rayInfo table must include diffraction_order.');
        end
        orders = rayInfo.diffraction_order;
    else
        orders = rayInfo;
    end
    orders = round(double(orders(:)));
    orders = orders(isfinite(orders));
end


function clipped = normalize_clipped_local(clipped, n)
    if isempty(clipped)
        clipped = false(n, 1);
    elseif isscalar(clipped)
        clipped = repmat(logical(clipped), n, 1);
    else
        clipped = logical(clipped(:));
        if numel(clipped) ~= n
            error('clipped must be scalar or match the number of orders.');
        end
    end
end


function C = centered_order_colormap_local(M)
    M = max(1, round(double(M)));
    negBoundary = [0.18 0.42 0.86];
    posBoundary = [0.90 0.36 0.16];
    midColor = [0.86 0.86 0.80];

    if exist('colMapGen', 'file') == 2
        rawMap = colMapGen(posBoundary, negBoundary, 2*M + 2, ...
            'midCol', midColor);
        if size(rawMap, 1) >= 2*M + 2
            C = [rawMap(1:M, :); rawMap((M + 3):(2*M + 2), :)];
            C = min(max(C, 0), 1);
            return
        end
    end

    negSide = zeros(M, 3);
    posSide = zeros(M, 3);
    for j = 1:M
        towardMid = (j - 1)/M;
        negSide(j, :) = blend_color_local( ...
            negBoundary, midColor, towardMid);

        orderMagnitude = j;
        towardMid = (M - orderMagnitude)/M;
        posSide(j, :) = blend_color_local( ...
            posBoundary, midColor, towardMid);
    end
    C = [negSide; posSide];
    C = min(max(C, 0), 1);
end


function color = blend_color_local(boundaryColor, midColor, towardMid)
    color = (1 - towardMid).*boundaryColor + towardMid.*midColor;
end


function label = order_label_local(m)
    if m > 0
        label = "m = +" + string(m);
    else
        label = "m = " + string(m);
    end
end
