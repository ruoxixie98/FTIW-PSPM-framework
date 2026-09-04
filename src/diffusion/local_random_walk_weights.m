function [d_local, index_global] = local_random_walk_weights( ...
        i, mask_idx, dim, mask_flat, map, R_sparse, connectivity_dict, cfg)
% Diffusion weights around one masked voxel.

idx = mask_idx(i);
[x, y, z] = ind2sub(dim, idx);
r = cfg.r;

x_min = max(1, x - r);
x_max = min(dim(1), x + r);
y_min = max(1, y - r);
y_max = min(dim(2), y + r);
z_min = max(1, z - r);
z_max = min(dim(3), z + r);

nx = x_max - x_min + 1;
ny = y_max - y_min + 1;
nz = z_max - z_min + 1;
[X, Y, Z] = ndgrid(x_min:x_max, y_min:y_max, z_min:z_max);
index_global = sub2ind(dim, X(:), Y(:), Z(:));
loc = map(index_global);

local_mask_flat = mask_flat(index_global);
valid_mask = loc > 0;
valid_idx = loc(valid_mask);
n_local = nx * ny * nz;

W = zeros(n_local, n_local);
if ~isempty(valid_idx)
    W(valid_mask, valid_mask) = full(R_sparse(valid_idx, valid_idx));
end

invalid_ids = find(local_mask_flat == 0);
W(invalid_ids, :) = 0;
W(:, invalid_ids) = 0;

dim_key = sprintf('%dx%dx%d', nx, ny, nz);
distance_mask = connectivity_dict(dim_key);
W = softmax_nonzero(W, cfg.ka) .* distance_mask;
W(isnan(W)) = 0;

row_sum = sum(W, 2);
row_sum(row_sum == 0) = 1;
P = spdiags(1 ./ row_sum, 0, n_local, n_local) * sparse(W);
P = (1 - cfg.rho) * P + cfg.rho * speye(n_local);

cx = x - x_min + 1;
cy = y - y_min + 1;
cz = z - z_min + 1;
center_index = sub2ind([nx, ny, nz], cx, cy, cz);

d = zeros(n_local, 1);
d(center_index) = 1;
for step_idx = 1:cfg.steps
    d = P' * d;
end

if sum(d) > 0
    d = d ./ sum(d);
end
d(local_mask_flat == 0) = 0;

% Keep the smallest set whose cumulative mass reaches lambda.
[d_sorted, sort_idx] = sort(d, 'descend');
total_d = sum(d_sorted);
if total_d <= 0
    d_local = zeros(size(d));
    return;
end
threshold_idx = find( ...
    cumsum(d_sorted) >= cfg.lambda * total_d, 1, 'first');
selected = sort_idx(1:threshold_idx);

d_local = zeros(size(d));
d_local(selected) = d(selected);
d_local = d_local ./ sum(d_local);
end

