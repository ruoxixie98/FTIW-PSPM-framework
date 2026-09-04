function run_data = preprocess_fmri_run(fmri_nii, mask_data, cfg, return_full_volume, Wstruct)
% Smooth task data, filter each voxel time series, and standardize it.

info = niftiinfo(fmri_nii);
fmri_data = read_nifti_data(fmri_nii, cfg.io.flip_x);

if ndims(fmri_data) ~= 4
    error('FTIW:InvalidFmri', 'Expected a 4-D NIfTI file: %s', fmri_nii);
end
if ~isequal(size(fmri_data, 1), size(mask_data, 1)) || ...
        ~isequal(size(fmri_data, 2), size(mask_data, 2)) || ...
        ~isequal(size(fmri_data, 3), size(mask_data, 3))
    error('FTIW:GridMismatch', ...
        'fMRI image size does not match the mask: %s', fmri_nii);
end

if return_full_volume
    fwhm_mm = cfg.task.smooth_fwhm_mm;
else
    fwhm_mm = 0;
end

if fwhm_mm > 0
    if numel(info.PixelDimensions) >= 3
        voxel_size_mm = double(info.PixelDimensions(1:3));
    else
        voxel_size_mm = cfg.task.voxel_size_mm;
    end
    sigma_vox = (fwhm_mm / 2.3548) ./ voxel_size_mm;
    smoothed = zeros(size(fmri_data), 'like', fmri_data);
    for t = 1:size(fmri_data, 4)
        smoothed(:, :, :, t) = imgaussfilt3( ...
            fmri_data(:, :, :, t), sigma_vox);
    end
    fmri_data = smoothed;
    clear smoothed;
end

mask_idx = find(mask_data(:) == 1);
fmri_flat = reshape(fmri_data, [], size(fmri_data, 4));
series = double(fmri_flat(mask_idx, :));
clear fmri_data fmri_flat;

if ~isempty(Wstruct)
    series = Wstruct * series;
end

series = bandpass_filter_timeseries( ...
    series, cfg.temporal.TR, cfg.temporal.low_freq, ...
    cfg.temporal.high_freq, cfg.temporal.filter_order);
series = zscore_rows(series);

if return_full_volume
    run_data = zeros(numel(mask_data), size(series, 2));
    run_data(mask_idx, :) = series;
else
    run_data = series;
end
end

