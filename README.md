# 🧪 MATLAB + GitHub Demo Project

> **A turnkey demonstration of how to use MATLAB in a professional, version-controlled workflow with Git & GitHub.**

[![MATLAB](https://img.shields.io/badge/MATLAB-R2023b%2B-blue?logo=mathworks)](https://mathworks.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Tests](https://img.shields.io/badge/tests-passing-brightgreen)](#-running-tests)

---

## 📖 Table of Contents

1. [Overview](#-overview)
2. [Project Structure](#-project-structure)
3. [Prerequisites](#-prerequisites)
4. [Getting Started](#-getting-started)
   - [Clone the Repository](#1-clone-the-repository)
   - [Open in MATLAB](#2-open-in-matlab)
   - [Run the Pipeline](#3-run-the-pipeline)
5. [MATLAB Environment Setup](#-matlab-environment-setup)
6. [Git & GitHub Integration](#-git--github-integration)
   - [Initial Git Setup](#step-1--initial-git-setup)
   - [Connecting to GitHub](#step-2--connecting-to-github)
   - [Daily Workflow](#step-3--daily-git-workflow)
   - [Branching Strategy](#step-4--branching-strategy)
   - [Using Git from MATLAB](#using-git-directly-from-matlab)
7. [Running Tests](#-running-tests)
8. [GitHub Actions CI (Optional)](#-github-actions-ci-optional)
9. [Project Functions Reference](#-project-functions-reference)
10. [Best Practices](#-best-practices)
11. [Troubleshooting](#-troubleshooting)
12. [License](#-license)

---

## 🔍 Overview

This project demonstrates a **complete, production-style MATLAB workflow** integrated with **Git** and **GitHub**. It is designed to show a client:

| Capability | What We Demonstrate |
|---|---|
| **MATLAB Environment** | Project bootstrapping via `startup.m`, clean folder layout, path management |
| **Signal Processing** | Synthetic signal generation, FFT spectral analysis, peak detection |
| **Automated Testing** | Full test suite using `matlab.unittest` framework |
| **Version Control** | Git initialisation, commits, branches, merge, `.gitignore`, `.gitattributes` |
| **GitHub Collaboration** | Remote push, pull requests, issue tracking, CI with GitHub Actions |
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
├── main.m                  # 🚀 Entry point — runs the full pipeline
├── startup.m               # 🔧 Auto-configures MATLAB paths on project open
├── runAllTests.m            # ✅ Runs the complete test suite
│
├── src/                    # 📦 Source functions
│   ├── generateSignal.m    #     Create multi-frequency test signal
│   ├── analyseSignal.m     #     FFT analysis + statistics
│   ├── visualiseResults.m  #     Publication-quality plots
│   └── generateReport.m    #     Text summary report generator
│
├── tests/                  # 🧪 Unit tests (matlab.unittest)
│   ├── TestGenerateSignal.m
│   └── TestAnalyseSignal.m
│
├── data/                   # 📊 Raw/generated data (git-ignored)
├── results/                # 📈 Output figures & reports (git-ignored)
├── docs/                   # 📝 Documentation & images
│   └── images/
│
├── .gitignore              # 🚫 Files excluded from version control
├── .gitattributes          # 📐 Line-ending & binary file rules
├── CONTRIBUTING.md         # 🤝 Contribution guidelines
├── LICENSE                 # ⚖️  MIT License
└── README.md               # 📖 This file
```

---

## ✅ Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| **MATLAB** | R2023b or later | Core development environment |
| **Signal Processing Toolbox** | (included in most licenses) | `findpeaks` function |
| **Git** | 2.30+ | Version control |
| **GitHub account** | — | Remote repository hosting |

### Verify Git is installed

```bash
git --version
# Expected: git version 2.x.x
```

### Verify MATLAB from the command line (optional)

```bash
matlab -batch "disp('MATLAB is ready')"
```

---

## 🚀 Getting Started

### 1. Clone the Repository

```bash
# HTTPS
git clone https://github.com/<your-username>/matlab-github-demo.git

# or SSH
git clone git@github.com:<your-username>/matlab-github-demo.git

cd matlab-github-demo
```

### 2. Open in MATLAB

Open MATLAB and navigate to the project folder:

```matlab
cd('C:\path\to\matlab-github-demo')
% startup.m runs automatically and configures paths
```

You should see:

```
MATLAB-GitHub-Demo project loaded.
  Project root : C:\path\to\matlab-github-demo
  Type "main" to run the full pipeline.
```

### 3. Run the Pipeline

```matlab
>> main
```

**Expected output:**

```
=== MATLAB + GitHub Demo Pipeline ===
Sample Rate  : 1000 Hz
Duration     : 2.0 s
Signal Freqs : [5 12 30] Hz
Noise Level  : 0.30

[1/4] Generating synthetic data …
      Saved → data/raw_signal.mat
[2/4] Running analysis …
[3/4] Generating plots …
      Exported → results/TimeDomain.png
      Exported → results/FrequencySpectrum.png
      Exported → results/StatsSummary.png
[4/4] Saving results …
      Saved → results/analysis_results.mat
      Report → results/summary_report.txt

=== Pipeline complete ===
```

---

## 🔧 MATLAB Environment Setup

### How `startup.m` Works

When you `cd` into the project root, MATLAB automatically runs `startup.m`, which:

1. **Adds `src/`** to the MATLAB search path
2. **Creates output directories** (`data/`, `results/`) if they don't exist
3. **Prints a welcome message** confirming the project is loaded

### Manual Path Setup (if needed)

```matlab
addpath('src');
addpath('tests');
```

### Using MATLAB Projects (`.prj`) — Advanced

For larger teams, you can create a MATLAB Project:

```
MATLAB → Home tab → New → Project → From Folder → select matlab-github-demo/
```

This gives you:
- Dependency analysis
- Automated path management
- Shortcut buttons
- Built-in Git integration panel

---

## 🔗 Git & GitHub Integration

This section walks through the **complete Git + GitHub setup** step by step.

### Step 1 — Initial Git Setup

```bash
# Navigate to the project
cd matlab-github-demo

# Initialise a Git repository
git init

# Configure your identity (first time only)
git config user.name "Your Name"
git config user.email "you@example.com"

# Stage all project files
git add .

# Make the first commit
git commit -m "Initial commit: MATLAB signal processing demo"
```

### Step 2 — Connecting to GitHub

1. **Create a new repository** on [github.com](https://github.com/new)
   - Name: `matlab-github-demo`
   - Visibility: Public or Private
   - **Do NOT** initialise with README (we already have one)

2. **Link and push:**

```bash
git remote add origin https://github.com/<your-username>/matlab-github-demo.git
git branch -M main
git push -u origin main
```

### Step 3 — Daily Git Workflow

```bash
# 1. Check what changed
git status

# 2. See the actual changes
git diff

# 3. Stage specific files
git add src/analyseSignal.m

# 4. Or stage everything
git add .

# 5. Commit with a meaningful message
git commit -m "feat: add SNR estimation to analyseSignal"

# 6. Push to GitHub
git push
```

#### Commit Message Convention

We recommend [Conventional Commits](https://www.conventionalcommits.org/):

| Prefix | When to use | Example |
|--------|------------|---------|
| `feat:` | New feature | `feat: add bandpass filter` |
| `fix:` | Bug fix | `fix: correct FFT scaling` |
| `docs:` | Documentation | `docs: update README setup instructions` |
| `test:` | Adding tests | `test: add edge-case tests for generateSignal` |
| `refactor:` | Code restructure | `refactor: extract config to separate file` |
| `chore:` | Maintenance | `chore: update .gitignore` |

### Step 4 — Branching Strategy

```bash
# Create a feature branch
git checkout -b feature/bandpass-filter

# ... make changes ...
git add .
git commit -m "feat: implement bandpass filter function"

# Push the branch to GitHub
git push -u origin feature/bandpass-filter

# On GitHub: open a Pull Request → review → merge

# Back on your machine, sync
git checkout main
git pull
```

### Using Git Directly from MATLAB

MATLAB has a built-in Git panel (R2023b+):

```matlab
% Check current Git status from MATLAB
!git status

% Quick commit from MATLAB command window
!git add .
!git commit -m "update: improve visualisation colors"
!git push
```

Or use the **Current Folder** panel → right-click → **Source Control** menu.

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
  ✓ testPeakFrequencyDetected(Frequency=5)
  ✓ testPeakFrequencyDetected(Frequency=20)
  ✓ testPeakFrequencyDetected(Frequency=100)
  ✓ testReproducibility

=== Test Summary ===
Total : 12
Passed: 12
Failed: 0

All tests passed ✓
```

### Run a single test class

```matlab
results = runtests('tests/TestGenerateSignal.m');
disp(results);
```

---

## 🤖 GitHub Actions CI (Optional)

You can run MATLAB tests automatically on every push using [MATLAB Actions for GitHub](https://github.com/matlab-actions).

Create `.github/workflows/ci.yml`:

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
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Set up MATLAB
        uses: matlab-actions/setup-matlab@v2

      - name: Run tests
        uses: matlab-actions/run-tests@v2
        with:
          source-folder: src
          test-results-junit: results/test-results.xml
```

> ⚠️ **Note:** GitHub-hosted MATLAB runners require a [MATLAB license for CI](https://github.com/matlab-actions/setup-matlab#licensing).

---

## 📚 Project Functions Reference

### `generateSignal(fs, duration, freqs, noiseLevel)`

| Parameter | Type | Description |
|-----------|------|-------------|
| `fs` | double | Sampling frequency (Hz) |
| `duration` | double | Signal length (seconds) |
| `freqs` | double vector | Frequencies to superimpose (Hz) |
| `noiseLevel` | double | Std dev of Gaussian noise (default: 0.1) |

**Returns:** `[t, cleanSignal, noisySignal]`

---

### `analyseSignal(t, signal, fs)`

| Parameter | Type | Description |
|-----------|------|-------------|
| `t` | double vector | Time axis |
| `signal` | double vector | Input signal |
| `fs` | double | Sampling frequency (Hz) |

**Returns:** `results` struct with fields: `freq`, `powerSpectrum`, `peakFreqs`, `peakPowers`, `meanVal`, `stdVal`, `rmsVal`, `maxVal`, `minVal`, `snrEstimate`

---

### `visualiseResults(t, cleanSignal, noisySignal, results, config)`

Generates three figures: Time Domain, Frequency Spectrum, and Statistics Summary.

**Returns:** Array of figure handles

---

### `generateReport(results, config, outputPath)`

Writes a formatted text report to the specified path.

---

## 💡 Best Practices

### MATLAB

- ✅ Use **argument validation blocks** (`arguments … end`) for input checking
- ✅ Add **docstrings** with `%FUNCTIONNAME  One-line description` format
- ✅ Use `startup.m` for automatic path configuration
- ✅ Keep functions in `/src`, tests in `/tests`, data in `/data`
- ✅ Use `rng(seed)` for reproducible random results
- ✅ Export figures with `exportgraphics()` for consistent resolution

### Git & GitHub

- ✅ Commit **small, logical changes** — not entire days of work
- ✅ Write **meaningful commit messages** using conventional commits
- ✅ Use **branches** for features; merge via **Pull Requests**
- ✅ Add `.gitignore` to exclude generated files (`.mat`, `.png`, `.asv`)
- ✅ Add `.gitattributes` to handle binary MATLAB files properly
- ✅ Never commit **large data files** — use Git LFS or external storage
- ✅ Tag releases: `git tag -a v1.0.0 -m "First stable release"`

---

## 🛠 Troubleshooting

| Problem | Solution |
|---------|----------|
| `Undefined function 'generateSignal'` | Run `startup` or `addpath('src')` |
| `Undefined function 'findpeaks'` | Install the Signal Processing Toolbox |
| `git: command not found` | [Install Git](https://git-scm.com/downloads) and restart terminal |
| Figures don't export | Ensure `results/` directory exists: `mkdir('results')` |
| Merge conflicts in `.mat` files | Avoid committing binary `.mat` files; they can't be merged |
| MATLAB doesn't detect Git | Go to **Preferences → MATLAB → General → Source Control** and set the Git binary path |

---

## ⚖️ License

This project is licensed under the **MIT License** — see [LICENSE](LICENSE) for details.

---

<p align="center">
  <strong>Built with ❤️ using MATLAB & GitHub</strong><br>
  <em>A demonstration project for professional MATLAB workflows</em>
</p>
