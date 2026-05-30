function n = nparaxial_medium_index_at_z_yu(prescription, z, side)
%NPARAXIAL_MEDIUM_INDEX_AT_Z_YU Estimate local medium index from surfaces.
%
% side controls exact surface hits:
%   "before" returns the incident-side medium at z.
%   "after"  returns the medium after all elements at z.

    if ~isscalar(z) || ~isfinite(z)
        error('z must be a finite scalar.');
    end

    if nargin < 3 || isempty(side)
        side = "after";
    end
    side = lower(strtrim(string(side)));
    if ~ismember(side, ["before", "after"])
        error('side must be "before" or "after".');
    end

    elements = nparaxial_enabled_elements_yu(prescription);
    if isempty(elements)
        n = 1;
        return
    end

    currentMedium = elements.n_before(1);
    tol = 1e-12;

    for k = 1:height(elements)
        zElement = elements.z(k);
        if z < zElement - tol
            n = currentMedium;
            return
        end

        if abs(z - zElement) <= tol && side == "before"
            n = currentMedium;
            return
        end

        if z >= zElement - tol && elements.type(k) == "surface"
            currentMedium = elements.n_after(k);
        end
    end

    n = currentMedium;
end
