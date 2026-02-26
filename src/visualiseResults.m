function figHandles = visualiseResults(t, cleanSignal, noisySignal, results, config)
%VISUALISERESULTS  Create publication-quality plots from the analysis.
%
%   figHandles = VISUALISERESULTS(t, cleanSignal, noisySignal, results, config)
%
%   Inputs
%   ------
%   t           — Time vector
%   cleanSignal — Noise-free reference signal
%   noisySignal — Signal with additive noise
%   results     — struct returned by analyseSignal
%   config      — struct with project configuration
%
%   Output
%   ------
%   figHandles  — Array of figure handles (for export)
%
%   See also GENERATESIGNAL, ANALYSESIGNAL

    figHandles = gobjects(1, 3);  % pre-allocate

    %% ---- Figure 1 : Time-domain signals ---------------------------------
    figHandles(1) = figure('Name', 'TimeDomain', 'Position', [100 100 900 400]);
    
    subplot(2,1,1);
    plot(t, cleanSignal, 'b', 'LineWidth', 1.2);
    title('Clean Signal (no noise)');
    xlabel('Time (s)'); ylabel('Amplitude');
    grid on;

    subplot(2,1,2);
    plot(t, noisySignal, 'Color', [0.8 0.2 0.2], 'LineWidth', 0.6);
    title(sprintf('Noisy Signal (\\sigma = %.2f)', config.noiseLevel));
    xlabel('Time (s)'); ylabel('Amplitude');
    grid on;

    sgtitle('Time-Domain View', 'FontWeight', 'bold');

    %% ---- Figure 2 : Frequency spectrum ----------------------------------
    figHandles(2) = figure('Name', 'FrequencySpectrum', 'Position', [100 550 900 400]);

    stem(results.freq, results.powerSpectrum, 'b', 'MarkerSize', 3);
    hold on;
    plot(results.peakFreqs, results.peakPowers, 'rv', ...
        'MarkerSize', 10, 'MarkerFaceColor', 'r');
    hold off;
    xlim([0 max(config.signalFreq) * 2]);
    title('Single-Sided Amplitude Spectrum');
    xlabel('Frequency (Hz)'); ylabel('|P1(f)|');
    legend('Spectrum', 'Detected Peaks', 'Location', 'northeast');
    grid on;

    % Annotate detected peaks
    for k = 1:numel(results.peakFreqs)
        text(results.peakFreqs(k), results.peakPowers(k) * 1.08, ...
            sprintf('%.1f Hz', results.peakFreqs(k)), ...
            'HorizontalAlignment', 'center', 'FontSize', 9, 'Color', 'r');
    end

    %% ---- Figure 3 : Statistics summary ----------------------------------
    figHandles(3) = figure('Name', 'StatsSummary', 'Position', [100 1000 500 350]);

    statLabels = {'Mean', 'Std Dev', 'RMS', 'Max', 'Min', 'SNR (dB)'};
    statValues = [results.meanVal, results.stdVal, results.rmsVal, ...
                  results.maxVal,  results.minVal, results.snrEstimate];

    barh(statValues, 'FaceColor', [0.2 0.6 0.8]);
    set(gca, 'YTick', 1:numel(statLabels), 'YTickLabel', statLabels);
    xlabel('Value');
    title('Signal Statistics');
    grid on;
end
