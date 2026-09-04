function cfg = validate_ftiw_config(cfg)
% Check paths and parameter ranges.

groups = {'paths', 'io', 'diffusion', 'temporal', ...
    'task', 'rest', 'parallel', 'cache'};
for i = 1:numel(groups)
    if ~isfield(cfg, groups{i})
        error('FTIW:MissingConfig', 'Missing cfg.%s.', groups{i});
    end
end

path_fields = {'mask_nii', 't1_nii', 't2_nii', ...
    'task_events', 'reference_nii', 'output_dir'};
require_fields(cfg.paths, path_fields, 'cfg.paths');
require_fields(cfg.io, {'flip_x'}, 'cfg.io');
require_fields(cfg.diffusion, ...
    {'r', 'ka', 'steps', 'rho', 'lambda', 'distance_power'}, ...
    'cfg.diffusion');
require_fields(cfg.temporal, ...
    {'TR', 'low_freq', 'high_freq', 'filter_order'}, 'cfg.temporal');
require_fields(cfg.task, ...
    {'smooth_fwhm_mm', 'voxel_size_mm', 'name', 'condition'}, 'cfg.task');
require_fields(cfg.rest, {'pca_variance'}, 'cfg.rest');
require_fields(cfg.parallel, ...
    {'use_parallel', 'num_workers'}, 'cfg.parallel');
require_fields(cfg.cache, ...
    {'reuse_existing', 'save_intermediate'}, 'cfg.cache');

cfg.paths.rest_nii = normalize_file_list(cfg.paths.rest_nii, 'rest_nii');
cfg.paths.task_nii = normalize_file_list(cfg.paths.task_nii, 'task_nii');
cfg.paths.task_events = normalize_file_list( ...
    cfg.paths.task_events, 'task_events');
if numel(cfg.paths.task_nii) ~= numel(cfg.paths.task_events)
    error('FTIW:EventRunMismatch', ...
        'Each task run must have one events file.');
end

input_files = [{
    cfg.paths.mask_nii
    cfg.paths.t1_nii
    cfg.paths.t2_nii
    cfg.paths.reference_nii
}; cfg.paths.rest_nii(:); cfg.paths.task_nii(:); ...
    cfg.paths.task_events(:)];
for i = 1:numel(input_files)
    if ~isfile(input_files{i})
        error('FTIW:FileNotFound', 'Input file not found: %s', input_files{i});
    end
end

must_be_scalar_integer(cfg.diffusion.r, 'cfg.diffusion.r', 0);
must_be_scalar_integer(cfg.diffusion.steps, 'cfg.diffusion.steps', 1);
must_be_finite_scalar(cfg.diffusion.ka, 'cfg.diffusion.ka');
must_be_finite_scalar(cfg.diffusion.rho, 'cfg.diffusion.rho');
must_be_finite_scalar(cfg.diffusion.lambda, 'cfg.diffusion.lambda');
must_be_finite_scalar( ...
    cfg.diffusion.distance_power, 'cfg.diffusion.distance_power');

if cfg.diffusion.rho < 0 || cfg.diffusion.rho > 1
    error('FTIW:InvalidConfig', 'cfg.diffusion.rho must be in [0, 1].');
end
if cfg.diffusion.ka < 0
    error('FTIW:InvalidConfig', 'cfg.diffusion.ka must be nonnegative.');
end
if cfg.diffusion.lambda <= 0 || cfg.diffusion.lambda > 1
    error('FTIW:InvalidConfig', 'cfg.diffusion.lambda must be in (0, 1].');
end
if cfg.diffusion.distance_power < 0
    error('FTIW:InvalidConfig', ...
        'cfg.diffusion.distance_power must be nonnegative.');
end

must_be_finite_scalar(cfg.temporal.TR, 'cfg.temporal.TR');
must_be_finite_scalar(cfg.temporal.low_freq, 'cfg.temporal.low_freq');
must_be_finite_scalar(cfg.temporal.high_freq, 'cfg.temporal.high_freq');
must_be_scalar_integer( ...
    cfg.temporal.filter_order, 'cfg.temporal.filter_order', 1);
if cfg.temporal.TR <= 0
    error('FTIW:InvalidConfig', 'cfg.temporal.TR must be positive.');
end
nyquist = 1 / (2 * cfg.temporal.TR);
if cfg.temporal.low_freq < 0 || ...
        cfg.temporal.high_freq <= cfg.temporal.low_freq || ...
        cfg.temporal.high_freq >= nyquist
    error('FTIW:InvalidConfig', ...
        'Temporal cutoffs must satisfy 0 <= low < high < Nyquist.');
end

must_be_finite_scalar( ...
    cfg.task.smooth_fwhm_mm, 'cfg.task.smooth_fwhm_mm');
if cfg.task.smooth_fwhm_mm < 0
    error('FTIW:InvalidConfig', ...
        'cfg.task.smooth_fwhm_mm must be nonnegative.');
end
if ~isnumeric(cfg.task.voxel_size_mm) || ...
        numel(cfg.task.voxel_size_mm) ~= 3 || ...
        any(~isfinite(cfg.task.voxel_size_mm)) || ...
        any(cfg.task.voxel_size_mm <= 0)
    error('FTIW:InvalidConfig', ...
        'cfg.task.voxel_size_mm must contain three positive values.');
end
if ~(ischar(cfg.task.condition) || ...
        (isstring(cfg.task.condition) && isscalar(cfg.task.condition)))
    error('FTIW:InvalidConfig', ...
        'cfg.task.condition must be a text scalar.');
end
cfg.task.condition = char(cfg.task.condition);

if ~((ischar(cfg.task.name) && isrow(cfg.task.name)) || ...
        (isstring(cfg.task.name) && isscalar(cfg.task.name)))
    error('FTIW:InvalidConfig', ...
        'cfg.task.name must be a text scalar.');
end
cfg.task.name = strtrim(char(cfg.task.name));
if isempty(regexp(cfg.task.name, ...
        '^[A-Za-z0-9][A-Za-z0-9_-]*$', 'once'))
    error('FTIW:InvalidConfig', ...
        ['cfg.task.name must start with a letter or number and contain ' ...
        'only letters, numbers, underscores, or hyphens.']);
end

must_be_finite_scalar(cfg.rest.pca_variance, 'cfg.rest.pca_variance');
if cfg.rest.pca_variance <= 0 || cfg.rest.pca_variance > 1
    error('FTIW:InvalidConfig', ...
        'cfg.rest.pca_variance must be in (0, 1].');
end
must_be_scalar_integer( ...
    cfg.parallel.num_workers, 'cfg.parallel.num_workers', 1);

logical_fields = {
    cfg.io.flip_x, 'cfg.io.flip_x'
    cfg.parallel.use_parallel, 'cfg.parallel.use_parallel'
    cfg.cache.reuse_existing, 'cfg.cache.reuse_existing'
    cfg.cache.save_intermediate, 'cfg.cache.save_intermediate'
};
for i = 1:size(logical_fields, 1)
    value = logical_fields{i, 1};
    if ~(islogical(value) && isscalar(value))
        error('FTIW:InvalidConfig', ...
            '%s must be a logical scalar.', logical_fields{i, 2});
    end
end

validate_nifti_geometry(cfg);
end

function require_fields(value, names, label)
for i = 1:numel(names)
    if ~isfield(value, names{i})
        error('FTIW:MissingConfig', 'Missing %s.%s.', label, names{i});
    end
end
end

function files = normalize_file_list(files, label)
if ischar(files) || (isstring(files) && isscalar(files))
    files = cellstr(files);
elseif isstring(files)
    files = cellstr(files(:));
end
if ~iscell(files) || isempty(files) || ...
        ~all(cellfun(@(x) ischar(x) || ...
        (isstring(x) && isscalar(x)), files))
    error('FTIW:InvalidConfig', '%s must contain one or more paths.', label);
end
files = cellfun(@char, files(:), 'UniformOutput', false);
end

function must_be_finite_scalar(value, label)
if ~isnumeric(value) || ~isscalar(value) || ~isfinite(value)
    error('FTIW:InvalidConfig', '%s must be a finite scalar.', label);
end
end

function must_be_scalar_integer(value, label, minimum)
must_be_finite_scalar(value, label);
if value ~= fix(value) || value < minimum
    error('FTIW:InvalidConfig', ...
        '%s must be an integer greater than or equal to %d.', label, minimum);
end
end
