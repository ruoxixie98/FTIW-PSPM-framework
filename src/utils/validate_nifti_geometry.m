function validate_nifti_geometry(cfg)
% Check image dimensions and geometry before loading the data.

mask_info = niftiinfo(cfg.paths.mask_nii);
if numel(mask_info.ImageSize) ~= 3
    error('FTIW:InvalidMask', 'The analysis mask must be 3-D.');
end

spatial_files = [{
    cfg.paths.t1_nii
    cfg.paths.t2_nii
    cfg.paths.reference_nii
}; cfg.paths.rest_nii(:); cfg.paths.task_nii(:)];
for i = 1:numel(spatial_files)
    info = niftiinfo(spatial_files{i});
    if numel(info.ImageSize) < 3 || ...
            ~isequal(info.ImageSize(1:3), mask_info.ImageSize(1:3))
        error('FTIW:GridMismatch', ...
            'Image dimensions do not match the mask: %s', spatial_files{i});
    end
    if any(abs(double(info.PixelDimensions(1:3)) - ...
            double(mask_info.PixelDimensions(1:3))) > 1e-6)
        error('FTIW:GridMismatch', ...
            'Voxel sizes do not match the mask: %s', spatial_files{i});
    end
    if has_transform(info) && has_transform(mask_info) && ...
            any(abs(double(info.Transform.T(:)) - ...
            double(mask_info.Transform.T(:))) > 1e-5)
        error('FTIW:GridMismatch', ...
            'Image transform does not match the mask: %s', spatial_files{i});
    end
end

min_frames = minimum_filter_length(cfg);
functional_files = [cfg.paths.rest_nii(:); cfg.paths.task_nii(:)];
for i = 1:numel(functional_files)
    info = niftiinfo(functional_files{i});
    if numel(info.ImageSize) ~= 4
        error('FTIW:InvalidFmri', ...
            'Functional input must be 4-D: %s', functional_files{i});
    end
    if info.ImageSize(4) < min_frames
        error('FTIW:ShortRun', ...
            'Functional input needs at least %d frames: %s', ...
            min_frames, functional_files{i});
    end
end
end

function value = has_transform(info)
value = isfield(info, 'Transform') && ~isempty(info.Transform) && ...
    isprop(info.Transform, 'T');
end

function min_frames = minimum_filter_length(cfg)
nyquist = 1 / (2 * cfg.temporal.TR);
if cfg.temporal.low_freq <= 0
    Wn = cfg.temporal.high_freq / nyquist;
    [b, a] = butter(cfg.temporal.filter_order, Wn, 'low');
else
    Wn = [cfg.temporal.low_freq, cfg.temporal.high_freq] ./ nyquist;
    [b, a] = butter(cfg.temporal.filter_order, Wn, 'bandpass');
end
min_frames = 3 * (max(numel(a), numel(b)) - 1) + 1;
end

