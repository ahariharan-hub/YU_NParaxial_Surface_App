function lines = nparaxial_matrix_to_text_yu(M, label)
%NPARAXIAL_MATRIX_TO_TEXT_YU Format a 2x2 matrix as compact text.

    if nargin < 2
        label = "M";
    end
    if ~isnumeric(M) || ~isequal(size(M), [2, 2])
        error('M must be a numeric 2x2 matrix.');
    end

    lines = [
        string(label) + " ="
        sprintf('[ %.12g  %.12g', M(1, 1), M(1, 2))
        sprintf('  %.12g  %.12g ]', M(2, 1), M(2, 2))
        ];
end
