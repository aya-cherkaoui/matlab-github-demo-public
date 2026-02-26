%% runAllTests.m — Execute the full test suite
% =========================================================================
% Run from the project root:
%   >> runAllTests
%
% This script discovers all test classes in /tests and runs them using
% the MATLAB Unit Testing Framework.
% =========================================================================

import matlab.unittest.TestSuite
import matlab.unittest.TestRunner
import matlab.unittest.plugins.DiagnosticsValidationPlugin

fprintf('=== Running Test Suite ===\n\n');

% Add source code to the path
addpath(fullfile(pwd, 'src'));
addpath(fullfile(pwd, 'tests'));

% Discover tests
suite = TestSuite.fromFolder('tests');

% Create a verbose runner
runner = TestRunner.withTextOutput('Verbosity', 3);

% Run
results = runner.run(suite);

% Summary
fprintf('\n=== Test Summary ===\n');
fprintf('Total : %d\n', numel(results));
fprintf('Passed: %d\n', sum([results.Passed]));
fprintf('Failed: %d\n', sum([results.Failed]));

% Return non-zero exit code for CI
if any([results.Failed])
    fprintf(2, '\n** SOME TESTS FAILED **\n');
else
    fprintf('\nAll tests passed ✓\n');
end
