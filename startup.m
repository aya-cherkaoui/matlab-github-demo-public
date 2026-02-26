function startup()
%STARTUP  Project bootstrap — runs automatically when MATLAB opens this folder.
%
%   Adds the /src directory to the MATLAB path so all project functions
%   are available without manual path configuration.
%
%   This file is detected automatically by MATLAB when you:
%     • cd into the project root, or
%     • set the project root as the MATLAB "Current Folder"

    projectRoot = fileparts(mfilename('fullpath'));

    % Add source folders to path
    addpath(fullfile(projectRoot, 'src'));

    % Ensure output directories exist
    dirs = {'results', 'data'};
    for k = 1:numel(dirs)
        d = fullfile(projectRoot, dirs{k});
        if ~exist(d, 'dir')
            mkdir(d);
        end
    end

    fprintf('MATLAB-GitHub-Demo project loaded.\n');
    fprintf('  Project root : %s\n', projectRoot);
    fprintf('  Type "main" to run the full pipeline.\n\n');
end
