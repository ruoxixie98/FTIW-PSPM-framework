% Example configuration for one subject.

project_root = fileparts(mfilename('fullpath'));

cfg.paths.mask_nii = fullfile(project_root, 'data', 'analysis_mask.nii.gz');
cfg.paths.t1_nii = fullfile(project_root, 'data', 'T1w.nii.gz');
cfg.paths.t2_nii = fullfile(project_root, 'data', 'T2w.nii.gz');
cfg.paths.rest_nii = {
    fullfile(project_root, 'data', 'rest_run_01.nii.gz')
    fullfile(project_root, 'data', 'rest_run_02.nii.gz')
};
cfg.paths.task_nii = {
    fullfile(project_root, 'data', 'task_run_01.nii.gz')
    fullfile(project_root, 'data', 'task_run_02.nii.gz')
};
cfg.paths.task_events = {
    fullfile(project_root, 'data', 'condition_events_run_01.txt')
    fullfile(project_root, 'data', 'condition_events_run_02.txt')
};
cfg.paths.reference_nii = cfg.paths.mask_nii;
cfg.paths.output_dir = fullfile( ...
    project_root, 'results', 'participant_01', 'condition_01');

% Model parameters.
cfg.io.flip_x = true;

cfg.diffusion.r = 5;
cfg.diffusion.ka = 2;
cfg.diffusion.steps = 2;
cfg.diffusion.rho = 0.25;
cfg.diffusion.lambda = 0.95;
cfg.diffusion.distance_power = 4.5;

cfg.temporal.TR = 0.72;
cfg.temporal.low_freq = 0.01;
cfg.temporal.high_freq = 0.18;
cfg.temporal.filter_order = 4;

cfg.task.smooth_fwhm_mm = 4;
cfg.task.voxel_size_mm = [2 2 2];
cfg.task.name = 'example_task';
cfg.task.condition = '';
cfg.rest.pca_variance = 0.90;

cfg.parallel.use_parallel = false;
cfg.parallel.num_workers = 4;

cfg.cache.reuse_existing = false;
cfg.cache.save_intermediate = true;

run_ftiw_pspm(cfg);
