function start_parallel_pool(num_workers)
% Use a local pool with the requested number of workers.

pool = gcp('nocreate');
if isempty(pool)
    parpool('local', num_workers);
elseif pool.NumWorkers ~= num_workers
    warning('FTIW:ExistingPool', ...
        'Using the existing pool with %d workers.', pool.NumWorkers);
end
end
