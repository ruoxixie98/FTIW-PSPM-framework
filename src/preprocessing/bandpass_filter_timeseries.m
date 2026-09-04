function filtered = bandpass_filter_timeseries(data, TR, low_freq, high_freq, filter_order)
% Zero-phase Butterworth filter for row-wise time series.

fs = 1 / TR;
nyquist = fs / 2;

if isempty(low_freq) || low_freq <= 0
    Wn = high_freq / nyquist;
    [b, a] = butter(filter_order, Wn, 'low');
elseif isempty(high_freq) || high_freq >= nyquist
    Wn = low_freq / nyquist;
    [b, a] = butter(filter_order, Wn, 'high');
else
    Wn = [low_freq, high_freq] ./ nyquist;
    [b, a] = butter(filter_order, Wn, 'bandpass');
end

filtered = filtfilt(b, a, double(data'))';
end

