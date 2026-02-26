function generateReport(results, config, outputPath)
%GENERATEREPORT  Write a plain-text summary report to disk.
%
%   GENERATEREPORT(results, config, outputPath)
%
%   Inputs
%   ------
%   results    — struct returned by analyseSignal
%   config     — project configuration struct
%   outputPath — full path for the output .txt file
%
%   See also ANALYSESIGNAL

    fid = fopen(outputPath, 'w');
    if fid == -1
        error('generateReport:fileOpen', 'Cannot open %s for writing.', outputPath);
    end
    cleanUp = onCleanup(@() fclose(fid));

    fprintf(fid, '==================================================\n');
    fprintf(fid, '  MATLAB + GitHub Demo — Analysis Summary Report\n');
    fprintf(fid, '  Generated: %s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
    fprintf(fid, '==================================================\n\n');

    fprintf(fid, '--- Configuration ---\n');
    fprintf(fid, 'Sample Rate   : %d Hz\n', config.sampleRate);
    fprintf(fid, 'Duration      : %.1f s\n', config.duration);
    fprintf(fid, 'Signal Freqs  : %s Hz\n', mat2str(config.signalFreq));
    fprintf(fid, 'Noise Level   : %.2f\n\n', config.noiseLevel);

    fprintf(fid, '--- Detected Peaks ---\n');
    for k = 1:numel(results.peakFreqs)
        fprintf(fid, '  Peak %d : %.2f Hz  (power = %.4f)\n', ...
            k, results.peakFreqs(k), results.peakPowers(k));
    end
    fprintf(fid, '\n');

    fprintf(fid, '--- Statistics ---\n');
    fprintf(fid, 'Mean          : %.6f\n', results.meanVal);
    fprintf(fid, 'Std Dev       : %.6f\n', results.stdVal);
    fprintf(fid, 'RMS           : %.6f\n', results.rmsVal);
    fprintf(fid, 'Max           : %.6f\n', results.maxVal);
    fprintf(fid, 'Min           : %.6f\n', results.minVal);
    fprintf(fid, 'SNR Estimate  : %.2f dB\n\n', results.snrEstimate);

    fprintf(fid, '==================================================\n');
    fprintf(fid, '  End of Report\n');
    fprintf(fid, '==================================================\n');
end
