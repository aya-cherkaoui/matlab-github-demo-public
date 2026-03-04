# MATLAB + GitHub Demo Project

A working demonstration of how to use MATLAB Online with Git and GitHub for version control, collaboration, and continuous integration.

---

## Table of Contents

1. [Overview](#overview)
2. [Project Structure](#project-structure)
3. [Prerequisites](#prerequisites)
4. [Getting Started](#getting-started)
5. [Environment Setup](#environment-setup)
6. [Git and GitHub Integration](#git-and-github-integration)
7. [Running Tests](#running-tests)
8. [CI with GitHub Actions](#ci-with-github-actions)
9. [Functions Reference](#functions-reference)
10. [Best Practices](#best-practices)
11. [Troubleshooting](#troubleshooting)
12. [License](#license)

---

## Overview

This project shows how to run a MATLAB signal-processing pipeline in MATLAB Online while keeping everything under version control with Git and GitHub.

What it covers:

- Setting up a MATLAB project that configures itself on open (`startup.m`)
- Writing clean, testable MATLAB functions with input validation
- Running an automated test suite (`matlab.unittest`)
- Using Git from the MATLAB command window (via `gitHelper.m` or `!git` commands)
- Pushing to GitHub, working with branches, and opening pull requests
- Optional CI with GitHub Actions

The pipeline itself generates a synthetic multi-frequency signal, runs FFT-based spectral analysis, detects frequency peaks, produces plots, and writes a summary report.

```
Generate Signal  ->  Analyse (FFT + Stats)  ->  Visualise  ->  Export Report
                                                     |
                                               Train Model (LSTM)
                                                     |
                                               Export ONNX  ->  Azure ML (Track + Deploy)
```

### Azure Machine Learning Integration

This project also demonstrates a full MLOps workflow with Azure ML:

- **Experiment tracking** — log metrics and artifacts to Azure ML via MLflow
- **Model training** — train an LSTM signal classifier in MATLAB
- **ONNX export** — export trained models for cross-platform deployment
- **Managed endpoints** — deploy models as REST APIs on Azure ML
- **CI/CD** — automated train → register → deploy pipeline via GitHub Actions

See [`docs/DEMO_AZURE_ML.md`](docs/DEMO_AZURE_ML.md) for the full demo scenario.

---

## Project Structure

```
matlab-github-demo/
|
|-- setupProject.m           Setup script (creates the full project from scratch)
|-- gitHelper.m              Git commands from the MATLAB command window
|-- main.m                   Entry point -- runs the full analysis pipeline
|-- startup.m                Auto-configures MATLAB paths when you cd into the project
|-- runAllTests.m            Runs the complete test suite
|
|-- src/
|   |-- generateSignal.m    Create multi-frequency test signal with noise
|   |-- analyseSignal.m     FFT analysis, peak detection, statistics
|   |-- visualiseResults.m  Publication-quality plots
|   |-- generateReport.m    Text summary report
|   |-- azureMLConnect.m    Connect MATLAB to Azure ML workspace (Python SDK)
|   |-- mainWithAzureML.m   Main pipeline with Azure ML tracking
|   |-- trainAndExportModel.m  Train LSTM classifier + export ONNX
|   |-- scoreMATLABToAzure.m   Call Azure ML endpoint from MATLAB
|
|-- azure-ml/
|   |-- config.json          Azure ML workspace configuration
|   |-- environment.yml      Custom environment (MATLAB Runtime)
|   |-- endpoint.yml         Managed online endpoint definition
|   |-- deployment.yml       Model deployment configuration
|   |-- train_job.yml        Azure ML training job definition
|   |-- docker-context/      Dockerfile for MATLAB Runtime environment
|   |-- scoring/             Scoring script + conda env for endpoint
|   |-- scripts/             Python training wrapper
|
|-- tests/
|   |-- TestGenerateSignal.m
|   |-- TestAnalyseSignal.m
|
|-- data/                    Generated data (git-ignored)
|-- results/                 Output figures and reports (git-ignored)
|-- docs/                    Additional documentation
|
|-- .gitignore
|-- .gitattributes
|-- .github/workflows/ci.yml
|-- CONTRIBUTING.md
|-- LICENSE
|-- README.md
```

---

## Prerequisites

- **MATLAB Online** -- [matlab.mathworks.com](https://matlab.mathworks.com) (MathWorks account required)
- **Signal Processing Toolbox** -- needed for `findpeaks` (included in most licences)
- **GitHub account** -- [github.com](https://github.com) (free tier works)

No local MATLAB install is required. Everything runs in the browser.

---

## Getting Started

### Option A -- Fresh setup with setupProject

Upload `setupProject.m` to MATLAB Online (drag and drop into the Current Folder panel), then run:

```matlab
>> setupProject
```

This creates the entire project: folders, source files, tests, Git config, and makes the initial commit.

Then:

```matlab
>> cd(fullfile(userpath, 'matlab-github-demo'))
>> main          % run the analysis pipeline
>> runAllTests   % run the test suite
```

### Option B -- Clone from GitHub

In MATLAB Online: **Home > New > Project > From Git**, then paste the repository URL.

```matlab
>> startup    % configure paths
>> main       % run the pipeline
```

---

## Environment Setup

### startup.m

When you `cd` into the project root, MATLAB runs `startup.m` automatically. It:

1. Adds `src/` to the MATLAB search path
2. Creates `data/` and `results/` directories if they don't exist
3. Prints a confirmation message

If paths aren't set for some reason, run manually:

```matlab
addpath('src');
addpath('tests');
```

### MATLAB Projects (.prj)

For larger teams you can also create a MATLAB Project: **Home > New > Project > From Folder**. This gives you dependency analysis, automated path management, and a Git panel in the GUI.

---

## Git and GitHub Integration

Three ways to use Git from MATLAB Online:

### Using gitHelper (wrapper script)

```matlab
gitHelper status                     % show changed files
gitHelper add                        % stage all changes
gitHelper add "src/analyseSignal.m"  % stage a specific file
gitHelper commit "fix: correct FFT"  % commit with message
gitHelper push                       % push to GitHub
gitHelper pull                       % pull latest changes
gitHelper log                        % view recent history
gitHelper info                       % show remote, branch, status
gitHelper branch "feature/new-algo"  % create and switch to branch
gitHelper checkout "main"            % switch branches
gitHelper setremote "https://..."    % set GitHub remote URL
gitHelper diff                       % view uncommitted changes
```

### Using MATLAB's Source Control UI

Right-click a file in the Current Folder panel > **Source Control**, or go to **Home > Project > Source Control**. The UI lets you stage, commit, push, pull, and resolve merge conflicts visually.

### Using shell commands

Prefix any Git command with `!`:

```matlab
!git status
!git add .
!git commit -m "fix: correct FFT scaling factor"
!git push
```

---

### Connecting to GitHub (first time)

1. Create a new repo at [github.com/new](https://github.com/new). Name it `matlab-github-demo`. Do not initialise with README, .gitignore, or licence -- we already have them.

2. In MATLAB Online:

```matlab
gitHelper setremote "https://github.com/YOUR-USERNAME/matlab-github-demo.git"
gitHelper push
```

For authentication, GitHub requires a **Personal Access Token** (not your password). Generate one at **GitHub > Settings > Developer settings > Personal access tokens > Tokens (classic)**. Select the `repo` scope.

---

### Daily workflow

```matlab
gitHelper pull                                   % sync with team
% ... edit files, run main, run tests ...
gitHelper status                                 % see what changed
gitHelper add                                    % stage changes
gitHelper commit "feat: add bandpass filter"     % commit
gitHelper push                                   % push to GitHub
```

### Branching and pull requests

```matlab
gitHelper branch "feature/improved-plots"        % create branch
% ... make changes ...
gitHelper add
gitHelper commit "feat: improve plot styling"
!git push -u origin feature/improved-plots       % push branch
```

On GitHub, open a Pull Request from the feature branch into `main`. After review and merge, sync locally:

```matlab
gitHelper checkout "main"
gitHelper pull
```

### Commit message convention

Use [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` -- new feature
- `fix:` -- bug fix
- `docs:` -- documentation change
- `test:` -- adding or updating tests
- `refactor:` -- code restructure without behaviour change
- `chore:` -- maintenance, tooling, config

---

## Running Tests

```matlab
>> runAllTests
```

Expected output:

```
=== Running Test Suite ===

Running TestAnalyseSignal
  passed - testOutputIsStruct
  passed - testRequiredFieldsExist
  passed - testPeakDetectionAccuracy
  passed - testRmsPositive
  passed - testSnrFiniteForCleanSignal

Running TestGenerateSignal
  passed - testOutputSizes
  passed - testCorrectNumberOfSamples
  passed - testZeroNoise
  passed - testPeakFrequencyDetected (Frequency=5)
  passed - testPeakFrequencyDetected (Frequency=20)
  passed - testPeakFrequencyDetected (Frequency=100)
  passed - testReproducibility

=== Test Summary ===
Total : 12
Passed: 12
Failed: 0

All tests passed.
```

Run a single test class:

```matlab
runtests('tests/TestGenerateSignal.m');
```

---

## CI with GitHub Actions

The file `.github/workflows/ci.yml` runs all tests automatically on every push and pull request to `main`:

```yaml
name: MATLAB CI
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: matlab-actions/setup-matlab@v2
      - uses: matlab-actions/run-tests@v2
        with:
          source-folder: src
          test-results-junit: results/test-results.xml
```

Note: GitHub-hosted MATLAB runners require a [MATLAB licence for CI](https://github.com/matlab-actions/setup-matlab#licensing).

---

## Functions Reference

### generateSignal(fs, duration, freqs, noiseLevel)

Creates a multi-frequency test signal with additive Gaussian noise.

Inputs: sampling frequency (Hz), signal length (seconds), vector of frequencies (Hz), noise standard deviation (default 0.1).

Returns: `[t, cleanSignal, noisySignal]`

### analyseSignal(t, signal, fs)

Runs FFT spectral analysis, peak detection, and computes descriptive statistics.

Returns a struct with fields: `freq`, `powerSpectrum`, `peakFreqs`, `peakPowers`, `meanVal`, `stdVal`, `rmsVal`, `maxVal`, `minVal`, `snrEstimate`.

### visualiseResults(t, cleanSignal, noisySignal, results, config)

Generates three figures: time-domain view, frequency spectrum with annotated peaks, and a statistics bar chart.

Returns an array of figure handles.

### generateReport(results, config, outputPath)

Writes a plain-text summary report to the given file path.

### gitHelper(command, arg)

Wrapper for common Git operations. See [Git and GitHub Integration](#using-githelper-wrapper-script) for the full command list.

---

## Best Practices

**MATLAB:**
- Use `arguments` blocks for input validation
- Add help comments in the `%FUNCTIONNAME  description` format
- Use `startup.m` for automatic path configuration
- Keep source in `src/`, tests in `tests/`, data in `data/`
- Seed the RNG (`rng(42)`) for reproducible results
- Export figures with `exportgraphics()` for consistent resolution

**Git and GitHub:**
- Commit small, focused changes -- not a whole day of work
- Write clear commit messages following the conventional format
- Work on feature branches; merge through pull requests
- Use `.gitignore` to exclude generated files (`.mat`, `.png`, `.asv`)
- Use `.gitattributes` to handle binary MATLAB files across platforms
- Don't commit large data files -- use Git LFS or external storage
- Tag releases: `!git tag -a v1.0.0 -m "First stable release"`

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `Undefined function 'generateSignal'` | Run `startup` or `addpath('src')` |
| `Undefined function 'findpeaks'` | Install the Signal Processing Toolbox |
| Git commands fail in MATLAB Online | Check Preferences > MATLAB > Source Control |
| Push rejected by GitHub | Use a Personal Access Token, not your password |
| Figures don't export | Make sure `results/` exists: `mkdir('results')` |
| Merge conflicts in `.mat` files | Don't commit binary `.mat` files -- they can't be merged |
| MATLAB can't find project files | `cd` to the project root, then run `startup` |

---

## License

MIT License -- see [LICENSE](LICENSE) for details.
