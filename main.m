%% MATLAB + GitHub Demo Project — Main Entry Point
% =========================================================================
% Project : matlab-github-demo
% Author  : Ayac
% Date    : 2026-02-26
% Purpose : Demonstrate a professional MATLAB workflow integrated with Git
%           and GitHub for version control, collaboration, and CI/CD.
% =========================================================================
%
% This script orchestrates the full analysis pipeline:
%   1. Generate or load sample data
%   2. Perform signal processing & statistical analysis
%   3. Visualise results and export figures
%   4. Save results to the /results folder
%
% Usage:
%   >> main          % run from the project root
%
% =========================================================================

clear; clc; close all;

%% ---- Configuration -----------------------------------------------------
config.sampleRate   = 1000;        % Hz
config.duration     = 2;           % seconds
config.noiseLevel   = 0.3;         % amplitude of additive noise
config.signalFreq   = [5, 12, 30]; % Hz — frequencies in the test signal
config.outputDir    = fullfile(pwd, 'results');
config.dataDir      = fullfile(pwd, 'data');

fprintf('=== MATLAB + GitHub Demo Pipeline ===\n');
fprintf('Sample Rate  : %d Hz\n', config.sampleRate);
fprintf('Duration     : %.1f s\n', config.duration);
fprintf('Signal Freqs : %s Hz\n', mat2str(config.signalFreq));
fprintf('Noise Level  : %.2f\n\n', config.noiseLevel);

%% ---- Step 1 : Generate synthetic data ----------------------------------
fprintf('[1/4] Generating synthetic data …\n');
[t, cleanSignal, noisySignal] = generateSignal( ...
    config.sampleRate, config.duration, ...
    config.signalFreq, config.noiseLevel);

% Save raw data
save(fullfile(config.dataDir, 'raw_signal.mat'), ...
     't', 'cleanSignal', 'noisySignal', 'config');
fprintf('      Saved → data/raw_signal.mat\n');

%% ---- Step 2 : Analyse the signal ---------------------------------------
fprintf('[2/4] Running analysis …\n');
analysisResults = analyseSignal(t, noisySignal, config.sampleRate);

%% ---- Step 3 : Visualise ------------------------------------------------
fprintf('[3/4] Generating plots …\n');
figHandles = visualiseResults(t, cleanSignal, noisySignal, analysisResults, config);

% Export figures
for k = 1:numel(figHandles)
    figName = get(figHandles(k), 'Name');
    safeName = matlab.lang.makeValidName(figName);
    exportgraphics(figHandles(k), ...
        fullfile(config.outputDir, [safeName '.png']), 'Resolution', 150);
    fprintf('      Exported → results/%s.png\n', safeName);
end

%% ---- Step 4 : Save results ---------------------------------------------
fprintf('[4/4] Saving results …\n');
save(fullfile(config.outputDir, 'analysis_results.mat'), 'analysisResults');
fprintf('      Saved → results/analysis_results.mat\n');

% Generate a summary report (text)
reportPath = fullfile(config.outputDir, 'summary_report.txt');
generateReport(analysisResults, config, reportPath);
fprintf('      Report → results/summary_report.txt\n');

fprintf('\n=== Pipeline complete ===\n');
