function struct_data = encode_structural_data(t1_nii, t2_nii, mask_data, flip_x)
% T1w and T2w z-scores inside the analysis mask.

fprintf('Reading structural images...\n');
t1_data = read_nifti_data(t1_nii, flip_x);
t2_data = read_nifti_data(t2_nii, flip_x);

assert(isequal(size(t1_data), size(mask_data)), ...
    'T1w image size does not match the mask.');
assert(isequal(size(t2_data), size(mask_data)), ...
    'T2w image size does not match the mask.');

mask_idx = find(mask_data(:) == 1);
t1_z = zscore_vector(t1_data(mask_idx));
t2_z = zscore_vector(t2_data(mask_idx));
struct_data = [t1_z, t2_z];
end

