function outfile = calculate_PSPM( ...
        output_dir, reference_nii, Fdiff, task_data, mask_data, cfg)
% Compute a PSPM map from task data and functional diffusion weights.

fprintf('Calculating PSPM...\n');
dim = size(mask_data);
mask_idx = find(mask_data(:) == 1);
Fdiff = sparse(Fdiff);
r = cfg.diffusion.r;

pspm_values = zeros(numel(mask_idx), 1);
if cfg.parallel.use_parallel
    start_parallel_pool(cfg.parallel.num_workers);
    parfor i = 1:numel(mask_idx)
        pspm_values(i) = calculate_single_voxel_pspm( ...
            i, mask_idx, dim, r, Fdiff, task_data);
    end
else
    for i = 1:numel(mask_idx)
        pspm_values(i) = calculate_single_voxel_pspm( ...
            i, mask_idx, dim, r, Fdiff, task_data);
    end
end

pspm_3d = zeros(dim);
pspm_3d(mask_idx) = pspm_values;
pspm_3d(~isfinite(pspm_3d)) = 0;

outfile = fullfile(output_dir, ['PSPM_' cfg.task.name '.nii']);
write_metric_nifti( ...
    pspm_3d, reference_nii, outfile, cfg.io.flip_x);
end

function value = calculate_single_voxel_pspm( ...
        i, mask_idx, dim, r, Fdiff, task_data)
idx = mask_idx(i);
[x, y, z] = ind2sub(dim, idx);

x_min = max(1, x - r);
x_max = min(dim(1), x + r);
y_min = max(1, y - r);
y_max = min(dim(2), y + r);
z_min = max(1, z - r);
z_max = min(dim(3), z + r);

[X, Y, Z] = ndgrid(x_min:x_max, y_min:y_max, z_min:z_max);
index_global = sub2ind(dim, X(:), Y(:), Z(:));
n_local = numel(index_global);

d_local = Fdiff(1:n_local, i);
nz_idx = find(d_local ~= 0);
if isempty(nz_idx)
    value = 0;
    return;
end

[weights, order] = sort(full(d_local(nz_idx)), 'descend');
index_sorted = index_global(nz_idx(order));
neighbors_ts = task_data(index_sorted, :) .* weights;
if isempty(neighbors_ts) || all(neighbors_ts(:) == 0)
    value = 0;
    return;
end

[u1, s1, v1] = svds(neighbors_ts, 1, 'largest');

% Fix the SVD orientation with the first spatial loading.
orientation = sign(u1(1));
if orientation == 0
    orientation = 1;
end
direction = sign(sum(orientation .* v1(:)));
if direction == 0
    direction = 1;
end
value = full(s1(1, 1)) * direction;
end
