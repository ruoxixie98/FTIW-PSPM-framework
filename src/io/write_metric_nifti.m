function write_metric_nifti(volume, reference_nii, out_file, flip_x)
% Write a single-precision 3-D NIfTI using a reference header.

info = niftiinfo(reference_nii);
out_volume = single(volume);
if flip_x
    out_volume = flip(out_volume, 1);
end

if numel(info.ImageSize) > 3
    info.ImageSize = info.ImageSize(1:3);
end
if numel(info.PixelDimensions) > 3
    info.PixelDimensions = info.PixelDimensions(1:3);
end
info.Datatype = 'single';
info.BitsPerPixel = 32;

niftiwrite(out_volume, out_file, info, 'Compressed', false);
end

