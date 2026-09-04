function Fdiff = build_function_diffusion_matrix( ...
        mask_data, R_func, connectivity_dict, diffusion_cfg, parallel_cfg)
% Functional diffusion weights for masked voxels.

fprintf('Building functional diffusion weights...\n');
dim = size(mask_data);
mask_idx = find(mask_data(:) == 1);
n_vox = numel(mask_idx);
mask_flat = mask_data(:);

map = zeros(prod(dim), 1);
map(mask_idx) = 1:n_vox;

max_local = (2 * diffusion_cfg.r + 1) ^ 3;
Fdiff = zeros(max_local, n_vox);

if parallel_cfg.use_parallel
    start_parallel_pool(parallel_cfg.num_workers);
    parfor i = 1:n_vox
        Fdiff(:, i) = function_weights_for_voxel( ...
            i, mask_idx, dim, mask_flat, map, ...
            R_func, connectivity_dict, diffusion_cfg, max_local);
    end
else
    for i = 1:n_vox
        Fdiff(:, i) = function_weights_for_voxel( ...
            i, mask_idx, dim, mask_flat, map, ...
            R_func, connectivity_dict, diffusion_cfg, max_local);
    end
end
end

function weights_padded = function_weights_for_voxel( ...
        i, mask_idx, dim, mask_flat, map, ...
        R_func, connectivity_dict, cfg, max_local)
[d_local, ~] = local_random_walk_weights( ...
    i, mask_idx, dim, mask_flat, map, ...
    R_func, connectivity_dict, cfg);
weights_padded = zeros(max_local, 1);
weights_padded(1:numel(d_local)) = d_local;
end

