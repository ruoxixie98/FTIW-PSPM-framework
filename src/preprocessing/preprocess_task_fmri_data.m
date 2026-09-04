function [task_data, events_used] = preprocess_task_fmri_data( ...
        task_nii, task_events, mask_data, cfg)
% Align and average task events across runs.

fprintf('Preprocessing task-state data...\n');
if ischar(task_nii) || isstring(task_nii)
    task_nii = cellstr(task_nii);
end
if ischar(task_events) || isstring(task_events)
    task_events = cellstr(task_events);
end
if numel(task_nii) ~= numel(task_events)
    error('FTIW:EventRunMismatch', ...
        'Each task run must have one events file.');
end

event_sets = cell(numel(task_nii), 1);
volume_ranges = cell(numel(task_nii), 1);
total_events = 0;
max_event_volumes = 0;
for run_idx = 1:numel(task_nii)
    events = read_task_events( ...
        task_events{run_idx}, cfg.task.condition);
    info = niftiinfo(task_nii{run_idx});
    ranges = zeros(height(events), 2);
    for event_idx = 1:height(events)
        [ranges(event_idx, 1), ranges(event_idx, 2)] = ...
            event_to_volume_range( ...
            events.onset(event_idx), events.duration(event_idx), ...
            cfg.temporal.TR, info.ImageSize(4));
    end
    event_sets{run_idx} = events;
    volume_ranges{run_idx} = ranges;
    total_events = total_events + height(events);
    max_event_volumes = max( ...
        max_event_volumes, max(ranges(:, 2) - ranges(:, 1) + 1));
end

task_sum = zeros(numel(mask_data), max_event_volumes);
run_count = zeros(1, max_event_volumes);

run_col = zeros(total_events, 1);
event_col = zeros(total_events, 1);
file_col = strings(total_events, 1);
type_col = strings(total_events, 1);
onset_col = zeros(total_events, 1);
duration_col = zeros(total_events, 1);
amplitude_col = zeros(total_events, 1);
first_col = zeros(total_events, 1);
last_col = zeros(total_events, 1);
n_volume_col = zeros(total_events, 1);

row = 0;
for run_idx = 1:numel(task_nii)
    fprintf('  Task run %d/%d: %s\n', ...
        run_idx, numel(task_nii), task_nii{run_idx});
    run_data = preprocess_fmri_run( ...
        task_nii{run_idx}, mask_data, cfg, true, []);
    events = event_sets{run_idx};
    ranges = volume_ranges{run_idx};
    run_sum = zeros(numel(mask_data), max_event_volumes);
    event_count = zeros(1, max_event_volumes);

    for event_idx = 1:height(events)
        first_volume = ranges(event_idx, 1);
        last_volume = ranges(event_idx, 2);
        n_event_volumes = last_volume - first_volume + 1;
        run_sum(:, 1:n_event_volumes) = ...
            run_sum(:, 1:n_event_volumes) + ...
            run_data(:, first_volume:last_volume);
        event_count(1:n_event_volumes) = ...
            event_count(1:n_event_volumes) + 1;

        row = row + 1;
        run_col(row) = run_idx;
        event_col(row) = event_idx;
        file_col(row) = string(task_events{run_idx});
        type_col(row) = events.trial_type(event_idx);
        onset_col(row) = events.onset(event_idx);
        duration_col(row) = events.duration(event_idx);
        amplitude_col(row) = events.amplitude(event_idx);
        first_col(row) = first_volume;
        last_col(row) = last_volume;
        n_volume_col(row) = n_event_volumes;
    end

    valid_time = event_count > 0;
    task_sum(:, valid_time) = task_sum(:, valid_time) + ...
        run_sum(:, valid_time) ./ event_count(valid_time);
    run_count(valid_time) = run_count(valid_time) + 1;
end

task_data = task_sum ./ run_count;
task_data(~isfinite(task_data)) = 0;
events_used = table( ...
    run_col, event_col, file_col, type_col, onset_col, duration_col, ...
    amplitude_col, first_col, last_col, n_volume_col, ...
    'VariableNames', {'run_index', 'event_index', 'event_file', ...
    'trial_type', 'onset_seconds', 'duration_seconds', 'amplitude', ...
    'first_volume', 'last_volume', 'n_volumes'});
end
