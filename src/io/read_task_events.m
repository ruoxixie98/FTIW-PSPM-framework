function events = read_task_events(event_file, condition)
% Read plain text or BIDS events.tsv timing.

if nargin < 2
    condition = '';
end
[~, file_label, extension] = fileparts(event_file);

if strcmpi(extension, '.tsv')
    source = readtable(event_file, 'FileType', 'text', ...
        'Delimiter', '\t', 'VariableNamingRule', 'preserve');
    onset_col = find_column(source, 'onset');
    duration_col = find_column(source, 'duration');
    if isempty(onset_col) || isempty(duration_col)
        error('FTIW:InvalidEvents', ...
            'BIDS events file needs onset and duration columns: %s', ...
            event_file);
    end
    onset = numeric_column(source, onset_col);
    duration = numeric_column(source, duration_col);

    type_col = find_column(source, 'trial_type');
    if isempty(type_col)
        trial_type = repmat(string(file_label), height(source), 1);
    else
        trial_type = string(source{:, type_col});
        trial_type = trial_type(:);
    end

    amplitude_col = find_column(source, 'amplitude');
    if isempty(amplitude_col)
        amplitude = ones(height(source), 1);
    else
        amplitude = numeric_column(source, amplitude_col);
        amplitude(~isfinite(amplitude)) = 1;
    end
else
    source = readmatrix(event_file, 'FileType', 'text');
    source = source(~all(isnan(source), 2), :);
    if isempty(source) || size(source, 2) < 2
        error('FTIW:InvalidEvents', ...
            'Text events file needs onset and duration columns: %s', event_file);
    end
    onset = double(source(:, 1));
    duration = double(source(:, 2));
    if size(source, 2) >= 3
        amplitude = double(source(:, 3));
        amplitude(~isfinite(amplitude)) = 1;
    else
        amplitude = ones(size(onset));
    end
    trial_type = repmat(string(file_label), numel(onset), 1);
end

if any(~isfinite(onset)) || any(~isfinite(duration)) || ...
        any(onset < 0) || any(duration <= 0)
    error('FTIW:InvalidEvents', ...
        'Event onsets must be nonnegative and durations must be positive: %s', ...
        event_file);
end

condition = string(condition);
if strlength(condition) > 0
    keep = strcmpi(trial_type, condition);
    onset = onset(keep);
    duration = duration(keep);
    amplitude = amplitude(keep);
    trial_type = trial_type(keep);
end
if isempty(onset)
    error('FTIW:NoEvents', ...
        'No matching events found in %s.', event_file);
end

events = table(onset, duration, amplitude, trial_type);
events = sortrows(events, {'onset', 'duration'});
end

function index = find_column(source, name)
index = find(strcmpi(source.Properties.VariableNames, name), 1, 'first');
end

function values = numeric_column(source, index)
raw = source{:, index};
if isnumeric(raw) || islogical(raw)
    values = double(raw);
else
    values = str2double(string(raw));
end
values = values(:);
end
