function rest_features = preprocess_rest_fmri_data(rest_nii, mask_data, Wstruct, cfg)
% Filter rest runs and retain the requested SVD variance.

fprintf('Preprocessing resting-state data...\n');
if ischar(rest_nii) || isstring(rest_nii)
    rest_nii = cellstr(rest_nii);
end

all_runs = cell(numel(rest_nii), 1);
for run_idx = 1:numel(rest_nii)
    fprintf('  Rest run %d/%d: %s\n', ...
        run_idx, numel(rest_nii), rest_nii{run_idx});
    all_runs{run_idx} = preprocess_fmri_run( ...
        rest_nii{run_idx}, mask_data, cfg, false, Wstruct);
end

rest_all = cat(2, all_runs{:});
clear all_runs;

[~, S, V] = svd(rest_all, 'econ');
variance = diag(S) .^ 2;
if sum(variance) <= 0
    error('FTIW:ZeroVariance', ...
        'Resting-state data have zero variance after preprocessing.');
end

cum_ratio = cumsum(variance) ./ sum(variance);
k = find(cum_ratio >= cfg.rest.pca_variance, 1, 'first');
rest_features = rest_all * V(:, 1:k);
rest_features(isnan(rest_features)) = 0;
end

