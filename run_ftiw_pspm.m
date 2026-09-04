function outfile = run_ftiw_pspm(cfg)
% Run FTIW-PSPM for one subject.

project_root = fileparts(mfilename('fullpath'));
addpath(genpath(fullfile(project_root, 'src')));

cfg = validate_ftiw_config(cfg);
if ~exist(cfg.paths.output_dir, 'dir')
    mkdir(cfg.paths.output_dir);
end

tag = make_param_tag(cfg);
mask_raw = read_nifti_data(cfg.paths.mask_nii, cfg.io.flip_x);
if ndims(mask_raw) ~= 3 || any(~isfinite(mask_raw(:)))
    error('FTIW:InvalidMask', 'The analysis mask must be a finite 3-D image.');
end
mask_data = double(mask_raw ~= 0);
if ~any(mask_data(:))
    error('FTIW:InvalidMask', 'The analysis mask is empty.');
end
clear mask_raw;

max_dim = repmat(2 * cfg.diffusion.r + 1, 1, 3);
connectivity_dict = build_connectivity_dictionary( ...
    max_dim, cfg.diffusion.distance_power);

Wstruct_file = fullfile(cfg.paths.output_dir, ...
    ['Wstruct_' tag.diffusion '.mat']);
if cfg.cache.reuse_existing && exist(Wstruct_file, 'file')
    cached = load(Wstruct_file, 'Wstruct');
    Wstruct = cached.Wstruct;
else
    struct_data = encode_structural_data( ...
        cfg.paths.t1_nii, cfg.paths.t2_nii, mask_data, cfg.io.flip_x);
    R_struct = build_neighbor_similarity_matrix( ...
        struct_data, mask_data, 'cosine', cfg.parallel);
    Wstruct = build_structural_smoothing_matrix( ...
        mask_data, R_struct, connectivity_dict, ...
        cfg.diffusion, cfg.parallel);
    if cfg.cache.save_intermediate
        save(Wstruct_file, 'Wstruct', '-v7.3');
    end
end

Fdiff_file = fullfile(cfg.paths.output_dir, ...
    ['Fdiff_' tag.diffusion '_' tag.rest '.mat']);
if cfg.cache.reuse_existing && exist(Fdiff_file, 'file')
    cached = load(Fdiff_file, 'Fdiff');
    Fdiff = cached.Fdiff;
else
    rest_features = preprocess_rest_fmri_data( ...
        cfg.paths.rest_nii, mask_data, Wstruct, cfg);
    if cfg.cache.save_intermediate
        save(fullfile(cfg.paths.output_dir, ...
            ['restFeat_' tag.rest '.mat']), 'rest_features', '-v7.3');
    end
    R_func = build_neighbor_similarity_matrix( ...
        rest_features, mask_data, 'pearson', cfg.parallel);
    Fdiff = build_function_diffusion_matrix( ...
        mask_data, R_func, connectivity_dict, ...
        cfg.diffusion, cfg.parallel);
    if cfg.cache.save_intermediate
        save(Fdiff_file, 'Fdiff', '-v7.3');
    end
end

[task_data, events_used] = preprocess_task_fmri_data( ...
    cfg.paths.task_nii, cfg.paths.task_events, mask_data, cfg);
writetable(events_used, ...
    fullfile(cfg.paths.output_dir, 'events_used.tsv'), ...
    'FileType', 'text', 'Delimiter', '\t');
if cfg.cache.save_intermediate
    save(fullfile(cfg.paths.output_dir, ...
        ['taskFull_' tag.task '.mat']), 'task_data', '-v7.3');
end

outfile = calculate_PSPM( ...
    cfg.paths.output_dir, cfg.paths.reference_nii, ...
    Fdiff, task_data, mask_data, cfg);
fprintf('FTIW-PSPM finished: %s\n', outfile);
end
