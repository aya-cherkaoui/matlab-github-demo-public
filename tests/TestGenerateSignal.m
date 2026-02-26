classdef TestGenerateSignal < matlab.unittest.TestCase
%TESTGENERATESIGNAL  Unit tests for the generateSignal function.

    properties (TestParameter)
        Frequency = {5, 20, 100}
    end

    methods (Test)

        function testOutputSizes(testCase)
            % All outputs must be the same length
            [t, c, n] = generateSignal(500, 1, [10], 0.1);
            testCase.verifyEqual(numel(t), numel(c));
            testCase.verifyEqual(numel(t), numel(n));
        end

        function testCorrectNumberOfSamples(testCase)
            fs = 1000; dur = 2;
            [t, ~, ~] = generateSignal(fs, dur, [5], 0);
            testCase.verifyEqual(numel(t), fs * dur);
        end

        function testZeroNoise(testCase)
            % With zero noise, clean and noisy must be identical
            [~, c, n] = generateSignal(1000, 1, [10 20], 0);
            testCase.verifyEqual(c, n, 'AbsTol', 1e-12);
        end

        function testPeakFrequencyDetected(testCase, Frequency)
            % The dominant FFT peak should match the input frequency
            fs = 1000; dur = 2;
            [~, ~, sig] = generateSignal(fs, dur, Frequency, 0);
            Y = fft(sig);
            N = numel(sig);
            P = abs(Y(1:floor(N/2)+1) / N);
            P(2:end-1) = 2 * P(2:end-1);
            freqAxis = fs * (0:floor(N/2)) / N;
            [~, idx] = max(P);
            testCase.verifyEqual(freqAxis(idx), Frequency, 'AbsTol', 1);
        end

        function testReproducibility(testCase)
            % Same parameters ⟹ same output (seeded RNG)
            [~, ~, n1] = generateSignal(1000, 1, [10], 0.5);
            [~, ~, n2] = generateSignal(1000, 1, [10], 0.5);
            testCase.verifyEqual(n1, n2);
        end
    end
end
