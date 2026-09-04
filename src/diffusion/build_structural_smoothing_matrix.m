function Wstruct = build_structural_smoothing_matrix( ...
        mask_data, R_struct, connectivity_dict, diffusion_cfg, parallel_cfg)
% Structural diffusion weights for masked voxels.

fprintf('Building structural diffusion weights...\n');
dim = size(mask_data);
mask_idx = find(mask_data(:) == 1);
n_vox = numel(mask_idx);
mask_flat = mask_data(:);

map = zeros(prod(dim), 1);
map(mask_idx) = 1:n_vox;

I_cell = cell(n_vox, 1);
J_cell = cell(n_vox, 1);
V_cell = cell(n_vox, 1);

if parallel_cfg.use_parallel
    start_parallel_pool(parallel_cfg.num_workers);
    parfor i = 1:n_vox
        [I_cell{i}, J_cell{i}, V_cell{i}] = ...
            structural_weights_for_voxel( ...
            i, mask_idx, dim, mask_flat, map, ...
            R_struct, connectivity_dict, diffusion_cfg);
    end
else
    for i = 1:n_vox
        [I_cell{i}, J_cell{i}, V_cell{i}] = ...
            structural_weights_for_voxel( ...
            i, mask_idx, dim, mask_flat, map, ...
            R_struct, connectivity_dict, diffusion_cfg);
    end
end

I_all = cat(1, I_cell{:});
J_all = cat(1, J_cell{:});
V_all = cat(1, V_cell{:});
Wstruct = sparse(I_all, J_all, V_all, n_vox, n_vox);
end

function [I, J, V] = structural_weights_for_voxel( ...
        i, mask_idx, dim, mask_flat, map, ...
        R_struct, connectivity_dict, cfg)
[d_local, index_global] = local_random_walk_weights( ...
    i, mask_idx, dim, mask_flat, map, ...
    R_struct, connectivity_dict, cfg);

nz_d = find(d_local ~= 0);
J = map(index_global(nz_d));
valid = J > 0;
I = repmat(i, sum(valid), 1);
J = J(valid);
V = d_local(nz_d(valid));
end

