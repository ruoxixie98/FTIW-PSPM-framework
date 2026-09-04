function [first_volume, last_volume] = event_to_volume_range( ...
        onset, duration, TR, n_volumes)
% Map a half-open event interval to overlapping fMRI volumes.

if ~isfinite(onset) || onset < 0 || ...
        ~isfinite(duration) || duration <= 0
    error('FTIW:InvalidEvents', 'Invalid event timing.');
end

run_duration = n_volumes * TR;
tolerance = 1e-9 * max(1, run_duration);
if onset + duration > run_duration + tolerance
    error('FTIW:EventOutOfRange', ...
        'Event ending at %.6g s exceeds the run duration of %.6g s.', ...
        onset + duration, run_duration);
end

scaled_start = snap_to_integer(onset / TR);
scaled_end = snap_to_integer((onset + duration) / TR);
first_volume = floor(scaled_start) + 1;
last_volume = ceil(scaled_end);

if first_volume < 1 || last_volume > n_volumes || ...
        last_volume < first_volume
    error('FTIW:EventOutOfRange', 'Event does not map to a valid volume range.');
end
end

function value = snap_to_integer(value)
nearest = round(value);
if abs(value - nearest) <= 1e-9 * max(1, abs(value))
    value = nearest;
end
end

