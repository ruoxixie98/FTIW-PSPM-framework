function R_sparse = build_neighbor_similarity_matrix(data_2d, mask_data, method, parallel_cfg)
% Similarity between masked voxels that share a corner, edge, or face.

fprintf('Building %s neighbour similarities...\n', lower(method));
dim = size(mask_data);
mask_idx = find(mask_data(:) == 1);
n_vox = numel(mask_idx);

map = zeros(prod(dim), 1);
map(mask_idx) = 1:n_vox;

offsets = zeros(26, 3);
offset_idx = 0;
for dx = -1:1
    for dy = -1:1
        for dz = -1:1
            if dx == 0 && dy == 0 && dz == 0
                continue;
            end
            offset_idx = offset_idx + 1;
            offsets(offset_idx, :) = [dx, dy, dz];
        end
    end
end

if strcmpi(method, 'pearson')
    data_use = zscore_rows(data_2d);
elseif strcmpi(method, 'cosine')
    norms = sqrt(sum(data_2d .^ 2, 2));
    data_use = data_2d ./ max(norms, eps);
else
    error('FTIW:UnknownSimilarity', ...
        'Unknown similarity method: %s', method);
end

rows_cell = cell(n_vox, 1);
cols_cell = cell(n_vox, 1);
vals_cell = cell(n_vox, 1);
n_features = size(data_use, 2);

if parallel_cfg.use_parallel
    start_parallel_pool(parallel_cfg.num_workers);
    parfor i = 1:n_vox
        [rows_cell{i}, cols_cell{i}, vals_cell{i}] = ...
            neighbor_similarity_for_voxel( ...
            i, mask_idx, map, dim, offsets, ...
            data_use, method, n_features);
    end
else
    for i = 1:n_vox
        [rows_cell{i}, cols_cell{i}, vals_cell{i}] = ...
            neighbor_similarity_for_voxel( ...
            i, mask_idx, map, dim, offsets, ...
            data_use, method, n_features);
    end
end

rows = cat(2, rows_cell{:});
cols = cat(2, cols_cell{:});
vals = cat(2, vals_cell{:});
R_sparse = sparse(rows, cols, vals, n_vox, n_vox);
fprintf('  Matrix: %d x %d, nonzeros: %d\n', ...
    n_vox, n_vox, nnz(R_sparse));
end

function [rr, cc, vv] = neighbor_similarity_for_voxel( ...
        i, mask_idx, map, dim, offsets, data_use, method, n_features)
[x, y, z] = ind2sub(dim, mask_idx(i));
rr = [];
cc = [];
vv = [];
feature_i = data_use(i, :);

for k = 1:size(offsets, 1)
    xn = x + offsets(k, 1);
    yn = y + offsets(k, 2);
    zn = z + offsets(k, 3);
    if xn < 1 || yn < 1 || zn < 1 || ...
            xn > dim(1) || yn > dim(2) || zn > dim(3)
        continue;
    end

    neighbor_lin = sub2ind(dim, xn, yn, zn);
    j = map(neighbor_lin);
    if j == 0
        continue;
    end

    feature_j = data_use(j, :);
    if strcmpi(method, 'pearson')
        similarity = (feature_i * feature_j') / max(n_features - 1, 1);
    else
        similarity = feature_i * feature_j';
    end

    rr(end + 1) = i; %#ok<AGROW>
    cc(end + 1) = j; %#ok<AGROW>
    vv(end + 1) = similarity; %#ok<AGROW>
end
end

