function y = softmax_nonzero(x, scale)
% Row-wise softmax over nonzero entries.

x = double(x);
mask = x ~= 0;
expx = exp(scale .* x) .* mask;
row_sum = sum(expx, 2);
row_sum(row_sum == 0) = 1;
y = expx ./ row_sum;
y(~mask) = 0;
end

