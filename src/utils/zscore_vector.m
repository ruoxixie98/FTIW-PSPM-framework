function data_z = zscore_vector(data)
% Standardize one vector.

data = double(data(:));
data_z = (data - mean(data)) ./ max(std(data), eps);
data_z(isnan(data_z)) = 0;
end

