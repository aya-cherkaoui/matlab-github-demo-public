# 🧪 MATLAB + GitHub Demo Project

> **A turnkey demonstration of how to use MATLAB Online in a professional, version-controlled workflow with Git & GitHub.**

[![MATLAB](https://img.shields.io/badge/MATLAB_Online-R2024a%2B-blue?logo=mathworks)](https://matlab.mathworks.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Tests](https://img.shields.io/badge/tests-passing-brightgreen)](#-running-tests)

---

## 📖 Table of Contents

1. [Overview](#-overview)
2. [Project Structure](#-project-structure)
3. [Prerequisites](#-prerequisites)
4. [Getting Started with MATLAB Online](#-getting-started-with-matlab-online)
5. [MATLAB Environment Setup](#-matlab-environment-setup)
6. [Git & GitHub Integration from MATLAB Online](#-git--github-integration-from-matlab-online)
   - [Method 1: Using the gitHelper tool](#method-1--using-the-githelper-tool-recommended)
   - [Method 2: Using MATLAB's Source Control UI](#method-2--using-matlabs-source-control-ui)
   - [Method 3: Using shell commands](#method-3--using-shell-commands-git)
   - [Connecting to GitHub](#connecting-to-github)
   - [Daily Workflow](#daily-git-workflow)
   - [Branching & Pull Requests](#branching--pull-requests)
7. [Running Tests](#-running-tests)
8. [GitHub Actions CI](#-github-actions-ci-optional)
9. [Functions Reference](#-functions-reference)
10. [Best Practices](#-best-practices)
11. [Troubleshooting](#-troubleshooting)
12. [License](#-license)

---

## 🔍 Overview

This project demonstrates a **complete, production-style MATLAB workflow** integrated with **Git** and **GitHub**, running entirely in **MATLAB Online**. It is designed to show a client:

| Capability | What We Demonstrate |
|---|---|
| **MATLAB Online** | Cloud-based MATLAB — no local install required |
| **Project Bootstrap** | One-script setup via `setupProject.m`, auto-path via `startup.m` |
| **Signal Processing** | Synthetic signal generation, FFT spectral analysis, peak detection |
| **Automated Testing** | Full test suite using `matlab.unittest` framework |
| **Version Control (Git)** | Init, commits, branches, merge — all from the MATLAB command window |
| **GitHub Collaboration** | Remote push/pull, pull requests, issue tracking, CI with GitHub Actions |
| **Reproducibility** | Seeded RNG, saved configs, generated reports |

### What does the pipeline do?

```
Generate Signal  ➜  Analyse (FFT + Stats)  ➜  Visualise  ➜  Export Report
```

---

## 📁 Project Structure

```
matlab-github-demo/
│
├── setupProject.m           # 🏗️  ONE-CLICK setup — creates the entire project
├── gitHelper.m              # 🔗 Git commands from MATLAB command window
├── main.m                   # 🚀 Entry point — runs the full analysis pipeline
├── startup.m                # 🔧 Auto-configures MATLAB paths on project open
├── runAllTests.m            # ✅ Runs the complete test suite
│
├── src/                     # 📦 Source functions
│   ├── generateSignal.m     #     Create multi-frequency test signal
│   ├── analyseSignal.m      #     FFT analysis + statistics
│   ├── visualiseResults.m   #     Publication-quality plots
│   └── generateReport.m     #     Text summary report generator
│
├── tests/                   # 🧪 Unit tests (matlab.unittest)
│   ├── TestGenerateSignal.m
│   └── TestAnalyseSignal.m
│
├── data/                    # 📊 Raw/generated data (git-ignored)
├── results/                 # 📈 Output figures & reports (git-ignored)
├── docs/                    # 📝 Additional documentation
│
├── .gitignore               # 🚫 Files excluded from version control
├── .gitattributes           # 📐 Line-ending & binary file rules
├── .github/workflows/ci.yml # 🤖 GitHub Actions CI pipeline
├── CONTRIBUTING.md          # 🤝 Contribution guidelines
├── LICENSE                  # ⚖️  MIT License
└── README.md                # 📖 This file
```

---

## ✅ Prerequisites

| Requirement | Details |
|-------------|---------|
| **MATLAB Online** | [matlab.mathworks.com](https://matlab.mathworks.com) — MathWorks account required |
| **MATLAB License** | Academic, Professional, or Home license with Online access |
| **Signal Processing Toolbox** | For `findpeaks` (included in most licenses) |
| **GitHub account** | [github.com](https://github.com) — free tier is sufficient |

> 💡 **No local install needed.** Everything runs in the browser via MATLAB Online.

---

## 🚀 Getting Started with MATLAB Online

### Option A — Fresh Setup (run `setupProject`)

If you are starting from scratch in MATLAB Online:

**Step 1:** Upload `setupProject.m` to your MATLAB Online drive (drag & drop into the Current Folder panel)

**Step 2:** Run it from the Command Window:

```matlab
>> setupProject
```

This single command will:
- ✅ Create the entire folder structure (`src/`, `tests/`, `data/`, `results/`, `docs/`)
- ✅ Write all source files, tests, and configuration files
- ✅ Configure the MATLAB path
- ✅ Initialise a local Git repository
- ✅ Make the initial commit

**Step 3:** Navigate to the project and run:

```matlab
>> cd(fullfile(userpath, 'matlab-github-demo'))
>> main          % run the analysis pipeline
>> runAllTests   % run the test suite
```

### Option B — Clone from GitHub

If the project is already on GitHub:

**Step 1:** In MATLAB Online, go to **Home → New → Project → From Git**

**Step 2:** Paste the repository URL:
```
https://github.com/<your-username>/matlab-github-demo.git
```

**Step 3:** MATLAB will clone the repo and set up the project. Then run:
```matlab
>> startup    % configure paths
>> main       % run the pipeline
```

---

## 🔧 MATLAB Environment Setup

### How `startup.m` Works

When you `cd` into the project root, MATLAB automatically runs `startup.m`, which:

1. **Adds `src/`** to the MATLAB search path — all functions become available
2. **Creates output directories** (`data/`, `results/`) if they don't exist
3. **Prints a welcome message** confirming the project is loaded

```
MATLAB-GitHub-Demo project loaded.
  Project root : /MATLAB Drive/matlab-github-demo
  Type "main" to run the full pipeline.
```

### Manual Path Setup (if needed)

```matlab
addpath('src');
addpath('tests');
```

### Using MATLAB Projects (`.prj`) — Optional

In MATLAB Online, you can also create a formal MATLAB Project for richer integration:

```
Home tab → New → Project → From Folder → select matlab-github-demo/
```

This gives you:
- Visual dependency graph
- Automated path management
- Shortcut buttons on the toolbar
- Built-in Git integration panel in the GUI

---

## 🔗 Git & GitHub Integration from MATLAB Online

MATLAB Online supports Git natively. Here are **three methods** to interact with Git:

---

### Method 1 — Using the `gitHelper` tool (Recommended)

The project includes `gitHelper.m`, a wrapper that gives you simple, memorable Git commands directly from the MATLAB Command Window:

```matlab
%% Check what files have changed
>> gitHelper status

%% Stage all changes for commit
>> gitHelper add

%% Stage a specific file only
>> gitHelper add "src/analyseSignal.m"

%% Commit staged changes with a message
>> gitHelper commit "feat: add SNR estimation to analyseSignal"

%% Push commits to GitHub
>> gitHelper push

%% Pull latest changes from GitHub
>> gitHelper pull

%% View recent commit history
>> gitHelper log

%% See remote URL, branch, and status at a glance
>> gitHelper info

%% Create a new feature branch and switch to it
>> gitHelper branch "feature/bandpass-filter"

%% Switch to an existing branch
>> gitHelper checkout "main"

%% View uncommitted code changes
>> gitHelper diff

%% Set the GitHub remote URL (first time setup)
>> gitHelper setremote "https://github.com/user/repo.git"
```

---

### Method 2 — Using MATLAB's Source Control UI

MATLAB Online has a built-in graphical Git interface:

1. **Current Folder panel** → right-click any file → **Source Control**
2. Or go to **Home tab → Project → Source Control**

From the UI you can:
- 📂 View modified files (highlighted in the Current Folder)
- ➕ Stage / unstage files
- 💬 Commit with a message
- ⬆️ Push / ⬇️ Pull
- 🌿 View branch history
- ⚔️ Resolve merge conflicts

> This is the most visual method and is great for demos.

---

### Method 3 — Using shell commands (`!git`)

You can run any raw Git command using the `!` prefix:

```matlab
>> !git status
>> !git add .
>> !git commit -m "fix: correct FFT scaling factor"
>> !git push
>> !git log --oneline -10
```

---

### Connecting to GitHub

**First time only** — link your local Git repository to a GitHub remote:

**Step 1:** Create a new repository on [github.com/new](https://github.com/new):
- **Name:** `matlab-github-demo`
- **Visibility:** Public or Private
- ⚠️ **Do NOT** initialise with README, .gitignore, or license (we already have all of these)

**Step 2:** In the MATLAB Online Command Window:

```matlab
>> gitHelper setremote "https://github.com/<your-username>/matlab-github-demo.git"
>> gitHelper push
```

> 🔑 **Authentication:** MATLAB Online will prompt you for GitHub credentials.
> 
> For HTTPS remotes, use a **Personal Access Token (PAT)** instead of your GitHub password:
> 1. Go to: **GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)**
> 2. Click **"Generate new token (classic)"**
> 3. Select scope: **`repo`** (full control of private repositories)
> 4. Copy the token and use it as your password when prompted

---

### Daily Git Workflow

A typical development session in MATLAB Online:

```matlab
%% 1. Start by pulling the latest changes (if collaborating)
>> gitHelper pull

%% 2. Do your work — edit files, run analysis, run tests
>> main
>> runAllTests

%% 3. Check what changed
>> gitHelper status

%% 4. Stage and commit with a descriptive message
>> gitHelper add
>> gitHelper commit "feat: add bandpass filter to analyseSignal"

%% 5. Push to GitHub
>> gitHelper push
```

---

### Branching & Pull Requests

For team collaboration, always work on feature branches:

```matlab
%% Create and switch to a new branch
>> gitHelper branch "feature/improved-plots"

%% ... make your changes in MATLAB Online ...
%% ... run tests to verify ...

%% Commit on the feature branch
>> gitHelper add
>> gitHelper commit "feat: improve plot styling and add peak annotations"

%% Push the feature branch to GitHub
>> !git push -u origin feature/improved-plots
```

Then on **GitHub.com**:
1. Open a **Pull Request** from `feature/improved-plots` → `main`
2. Add a description of what changed and why
3. Request a review from team members
4. After approval, click **Merge**

Back in **MATLAB Online**:
```matlab
>> gitHelper checkout "main"
>> gitHelper pull
```

#### Commit Message Convention

We use [Conventional Commits](https://www.conventionalcommits.org/) for a clean history:

| Prefix | When to use | Example |
|--------|------------|---------|
| `feat:` | New feature | `feat: add bandpass filter` |
| `fix:` | Bug fix | `fix: correct FFT scaling` |
| `docs:` | Documentation only | `docs: update README setup instructions` |
| `test:` | Adding/updating tests | `test: add edge-case tests for generateSignal` |
| `refactor:` | Code restructure (no new feature) | `refactor: extract config to separate file` |
| `chore:` | Maintenance / tooling | `chore: update .gitignore` |

---

## 🧪 Running Tests

```matlab
>> runAllTests
```

**Expected output:**

```
=== Running Test Suite ===

Running TestAnalyseSignal
  ✓ testOutputIsStruct
  ✓ testRequiredFieldsExist
  ✓ testPeakDetectionAccuracy
  ✓ testRmsPositive
  ✓ testSnrFiniteForCleanSignal

Running TestGenerateSignal
  ✓ testOutputSizes
  ✓ testCorrectNumberOfSamples
  ✓ testZeroNoise
  ✓ testPeakFrequencyDetected (Frequency=5)
  ✓ testPeakFrequencyDetected (Frequency=20)
  ✓ testPeakFrequencyDetected (Frequency=100)
  ✓ testReproducibility

=== Test Summary ===
Total : 12
Passed: 12
Failed: 0

All tests passed.
```

### Run a single test class

```matlab
>> runtests('tests/TestGenerateSignal.m')
```

---

## 🤖 GitHub Actions CI (Optional)

The project includes a GitHub Actions workflow at `.github/workflows/ci.yml` that automatically runs all MATLAB tests on every push and pull request to `main`.

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

> ⚠️ **Note:** GitHub-hosted MATLAB runners require a [MATLAB license for CI](https://github.com/matlab-actions/setup-matlab#licensing).

---

## 📚 Functions Reference

### `generateSignal(fs, duration, freqs, noiseLevel)`

Creates a multi-frequency test signal with additive Gaussian noise.

| Parameter | Type | Description |
|-----------|------|-------------|
| `fs` | double | Sampling frequency (Hz) |
| `duration` | double | Signal length (seconds) |
| `freqs` | double vector | Frequencies to superimpose (Hz) |
| `noiseLevel` | double | Std dev of noise (default: 0.1) |

**Returns:** `[t, cleanSignal, noisySignal]`

---

### `analyseSignal(t, signal, fs)`

Performs FFT spectral analysis, peak detection, and computes statistics.

| Parameter | Type | Description |
|-----------|------|-------------|
| `t` | double vector | Time axis |
| `signal` | double vector | Input signal |
| `fs` | double | Sampling frequency (Hz) |

**Returns:** struct with fields: `freq`, `powerSpectrum`, `peakFreqs`, `peakPowers`, `meanVal`, `stdVal`, `rmsVal`, `maxVal`, `minVal`, `snrEstimate`

---

### `visualiseResults(t, cleanSignal, noisySignal, results, config)`

Generates three publication-quality figures: Time Domain, Frequency Spectrum, Statistics Summary.

**Returns:** Array of figure handles

---

### `generateReport(results, config, outputPath)`

Writes a formatted plain-text summary report to the specified path.

---

### `gitHelper(command, arg)`

Wrapper for common Git operations from the MATLAB Command Window. See [Git Integration](#method-1--using-the-githelper-tool-recommended) for full command list.

---

## 💡 Best Practices

### MATLAB

| Practice | Why |
|----------|-----|
| Use `arguments` validation blocks | Input validation built into the language |
| Add `%FUNCTIONNAME` help blocks | Enables `help functionName` and auto-documentation |
| Use `startup.m` | Auto-configures paths when opening the project folder |
| Separate `src/`, `tests/`, `data/` | Clean, navigable, professional project layout |
| Use `rng(seed)` | Reproducible random results across runs and machines |
| Use `exportgraphics()` | Consistent figure export resolution |

### Git & GitHub

| Practice | Why |
|----------|-----|
| Commit small, logical changes | Easy to review, revert, and understand |
| Use conventional commit messages | Standardised, searchable history |
| Use branches for features | Isolate work; merge via Pull Requests |
| Add `.gitignore` | Don't track generated `.mat`, `.png`, `.asv` files |
| Add `.gitattributes` | Handle binary MATLAB files correctly across OS |
| Never commit large data files | Use Git LFS or external storage for big datasets |
| Tag releases | `!git tag -a v1.0.0 -m "First stable release"` |

---

## 🛠 Troubleshooting

| Problem | Solution |
|---------|----------|
| `Undefined function 'generateSignal'` | Run `startup` or `addpath('src')` |
| `Undefined function 'findpeaks'` | You need the Signal Processing Toolbox |
| Git commands fail in MATLAB Online | Check **Preferences → MATLAB → Source Control** is set to Git |
| Can't push to GitHub | Use a [Personal Access Token](https://github.com/settings/tokens) instead of password |
| Figures don't export | Ensure `results/` directory exists: `mkdir('results')` |
| Merge conflicts in `.mat` files | Don't commit binary `.mat` files — they can't be merged |
| `setupProject` says Git not available | Use MATLAB's GUI: right-click in Current Folder → Source Control |
| MATLAB Online can't find project files | Run `cd(fullfile(userpath, 'matlab-github-demo'))` then `startup` |

---

## ⚖️ License

This project is licensed under the **MIT License** — see [LICENSE](LICENSE) for details.

---

<p align="center">
  <strong>Built with ❤️ using MATLAB Online & GitHub</strong><br>
  <em>A demonstration project for professional cloud-based MATLAB workflows</em>
</p>
