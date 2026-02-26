function gitHelper(command, varargin)
%GITHELPER  Run common Git commands from the MATLAB Online Command Window.
%
%   GITHELPER(command)          — run a git command
%   GITHELPER(command, arg1)    — run with extra argument
%
%   Supported commands:
%   -------------------
%   gitHelper status                — show changed files
%   gitHelper add                   — stage all changes
%   gitHelper add "file.m"          — stage a specific file
%   gitHelper commit "message"      — commit staged changes
%   gitHelper push                  — push to remote (GitHub)
%   gitHelper pull                  — pull from remote
%   gitHelper log                   — show recent commit history
%   gitHelper branch                — list branches
%   gitHelper branch "name"         — create and switch to a new branch
%   gitHelper checkout "name"       — switch to an existing branch
%   gitHelper setremote "url"       — set the GitHub remote URL
%   gitHelper diff                  — show uncommitted changes
%   gitHelper info                  — show remote, branch, and status
%
%   Examples
%   --------
%       gitHelper status
%       gitHelper commit "feat: add bandpass filter"
%       gitHelper setremote "https://github.com/user/repo.git"
%       gitHelper push
%
%   See also SETUPPROJECT

    if nargin < 1 || isempty(command)
        error('gitHelper:noCommand', 'Usage: gitHelper <command> [arg]');
    end

    switch lower(command)

        case 'status'
            system('git status');

        case 'add'
            if ~isempty(varargin)
                system(sprintf('git add "%s"', varargin{1}));
            else
                system('git add .');
                fprintf('All changes staged.\n');
            end

        case 'commit'
            if isempty(varargin)
                error('gitHelper:noMessage', ...
                    'Usage: gitHelper commit "your commit message"');
            end
            msg = varargin{1};
            [status, result] = system(sprintf('git commit -m "%s"', msg));
            if status == 0
                fprintf('✓ Committed: %s\n', msg);
            else
                fprintf('%s\n', result);
            end

        case 'push'
            fprintf('Pushing to remote…\n');
            [status, result] = system('git push -u origin main');
            if status == 0
                fprintf('✓ Pushed successfully.\n');
            else
                fprintf('%s\n', result);
                fprintf('\nIf this is your first push, set the remote first:\n');
                fprintf('  gitHelper setremote "https://github.com/USER/REPO.git"\n');
            end

        case 'pull'
            system('git pull');

        case 'log'
            system('git log --oneline --graph --decorate -15');

        case 'branch'
            if ~isempty(varargin)
                branchName = varargin{1};
                system(sprintf('git checkout -b %s', branchName));
                fprintf('✓ Created and switched to branch: %s\n', branchName);
            else
                system('git branch -a');
            end

        case 'checkout'
            if isempty(varargin)
                error('gitHelper:noBranch', ...
                    'Usage: gitHelper checkout "branch-name"');
            end
            system(sprintf('git checkout %s', varargin{1}));

        case 'setremote'
            if isempty(varargin)
                error('gitHelper:noURL', ...
                    'Usage: gitHelper setremote "https://github.com/user/repo.git"');
            end
            url = varargin{1};
            % Remove existing remote if it exists
            system('git remote remove origin 2>/dev/null');
            [status, ~] = system(sprintf('git remote add origin %s', url));
            if status == 0
                fprintf('✓ Remote set to: %s\n', url);
                fprintf('  Now run: gitHelper push\n');
            end

        case 'diff'
            system('git diff');

        case 'info'
            fprintf('--- Git Info ---\n');
            system('git remote -v');
            fprintf('\n');
            system('git branch');
            fprintf('\n');
            system('git status -s');

        otherwise
            fprintf('Unknown command: %s\n', command);
            fprintf('Available commands: status, add, commit, push, pull, log, branch, checkout, setremote, diff, info\n');
    end
end
