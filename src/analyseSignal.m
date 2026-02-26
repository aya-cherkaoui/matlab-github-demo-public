function results = analyseSignal(t, signal, fs)
%ANALYSESIGNAL  Perform spectral and statistical analysis on a 1-D signal.
%
%   results = ANALYSESIGNAL(t, signal, fs)
%
%   Inputs
%   ------
%   t      — Time vector (1 × N)
%   signal — Signal samples (1 × N)
%   fs     — Sampling frequency (Hz)
%
%   Output
%   ------
%   results — struct with fields:
%       .freq            — Frequency axis (Hz)
%       .powerSpectrum   — One-sided power spectrum
%       .peakFreqs       — Detected peak frequencies (Hz)
%       .peakPowers      — Power at each detected peak
%       .meanVal         — Signal mean
%       .stdVal          — Signal standard deviation
%       .rmsVal          — Root-mean-square value
%       .maxVal          — Maximum amplitude
%       .minVal          — Minimum amplitude
%       .snrEstimate     — Estimated SNR (dB)
%
%   See also GENERATESIGNAL, VISUALISERESULTS

    arguments
        t      (1,:) double
        signal (1,:) double
        fs     (1,1) double {mustBePositive}
    end

    N = length(signal);

    %% ---- FFT-based spectral analysis ------------------------------------
    Y = fft(signal);
    P2 = abs(Y / N);                       % two-sided spectrum
    P1 = P2(1 : floor(N/2) + 1);           % one-sided
    P1(2:end-1) = 2 * P1(2:end-1);
    freq = fs * (0 : floor(N/2)) / N;

    results.freq          = freq;
    results.powerSpectrum = P1;

    %% ---- Peak detection -------------------------------------------------
    [pks, locs] = findpeaks(P1, freq, ...
        'MinPeakHeight',    max(P1) * 0.1, ...
        'MinPeakDistance',   2);

    results.peakFreqs  = locs;
    results.peakPowers = pks;

    %% ---- Basic statistics -----------------------------------------------
    results.meanVal = mean(signal);
    results.stdVal  = std(signal);
    results.rmsVal  = rms(signal);
    results.maxVal  = max(signal);
    results.minVal  = min(signal);

    %% ---- SNR estimate (signal power / noise floor) ----------------------
    signalPower = sum(pks.^2);
    totalPower  = sum(P1.^2);
    noisePower  = totalPower - signalPower;
    if noisePower > 0
        results.snrEstimate = 10 * log10(signalPower / noisePower);
    else
        results.snrEstimate = Inf;
    end
end
