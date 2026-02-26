function [t, cleanSignal, noisySignal] = generateSignal(fs, duration, freqs, noiseLevel)
%GENERATESIGNAL  Create a multi-frequency test signal with additive noise.
%
%   [t, cleanSignal, noisySignal] = GENERATESIGNAL(fs, duration, freqs, noiseLevel)
%
%   Inputs
%   ------
%   fs         — Sampling frequency (Hz)
%   duration   — Signal length (seconds)
%   freqs      — Vector of sine-wave frequencies to superimpose (Hz)
%   noiseLevel — Standard deviation of Gaussian noise added to cleanSignal
%
%   Outputs
%   -------
%   t           — Time vector  (1 × N)
%   cleanSignal — Sum-of-sines without noise  (1 × N)
%   noisySignal — cleanSignal + Gaussian noise (1 × N)
%
%   Example
%   -------
%       [t, c, n] = generateSignal(1000, 2, [5 12 30], 0.3);
%       plot(t, c, t, n);
%
%   See also ANALYSESIGNAL, VISUALISERESULTS

    arguments
        fs         (1,1) double {mustBePositive}
        duration   (1,1) double {mustBePositive}
        freqs      (1,:) double {mustBePositive}
        noiseLevel (1,1) double {mustBeNonnegative} = 0.1
    end

    % Time vector
    t = 0 : 1/fs : duration - 1/fs;

    % Build clean signal as sum of sinusoids
    cleanSignal = zeros(size(t));
    for f = freqs
        cleanSignal = cleanSignal + sin(2 * pi * f * t);
    end

    % Add Gaussian noise
    rng(42, 'twister');   % reproducible results
    noisySignal = cleanSignal + noiseLevel * randn(size(t));
end
