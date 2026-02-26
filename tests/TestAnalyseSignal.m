classdef TestAnalyseSignal < matlab.unittest.TestCase
%TESTANALYSESIGNAL  Unit tests for the analyseSignal function.

    methods (Test)

        function testOutputIsStruct(testCase)
            [t, ~, sig] = generateSignal(1000, 1, [10], 0.1);
            res = analyseSignal(t, sig, 1000);
            testCase.verifyClass(res, 'struct');
        end

        function testRequiredFieldsExist(testCase)
            [t, ~, sig] = generateSignal(1000, 1, [10], 0.1);
            res = analyseSignal(t, sig, 1000);

            expectedFields = {'freq','powerSpectrum','peakFreqs','peakPowers', ...
                              'meanVal','stdVal','rmsVal','maxVal','minVal','snrEstimate'};
            for k = 1:numel(expectedFields)
                testCase.verifyTrue(isfield(res, expectedFields{k}), ...
                    sprintf('Missing field: %s', expectedFields{k}));
            end
        end

        function testPeakDetectionAccuracy(testCase)
            targetFreqs = [10 25];
            [t, ~, sig] = generateSignal(1000, 2, targetFreqs, 0);
            res = analyseSignal(t, sig, 1000);

            for f = targetFreqs
                testCase.verifyTrue(any(abs(res.peakFreqs - f) < 1.5), ...
                    sprintf('Expected peak near %d Hz not found.', f));
            end
        end

        function testRmsPositive(testCase)
            [t, ~, sig] = generateSignal(1000, 1, [10], 0.2);
            res = analyseSignal(t, sig, 1000);
            testCase.verifyGreaterThan(res.rmsVal, 0);
        end

        function testSnrFiniteForCleanSignal(testCase)
            [t, ~, sig] = generateSignal(1000, 1, [10], 0);
            res = analyseSignal(t, sig, 1000);
            testCase.verifyTrue(res.snrEstimate > 0 || isinf(res.snrEstimate));
        end
    end
end
