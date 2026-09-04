function data = read_nifti_data(nii_file, flip_x)
% Read a NIfTI array and optionally reverse its first dimension.

data = double(niftiread(nii_file));
if flip_x
    data = flip(data, 1);
end
end

