function data_z = zscore_rows(data)
% Standardize each row.

mu = mean(data, 2);
sigma = std(data, 0, 2);
data_z = (data - mu) ./ max(sigma, eps);
data_z(isnan(data_z)) = 0;
end

