# Contributing to MATLAB-GitHub-Demo

Thank you for your interest in contributing! This document explains how to
collaborate on this project using Git and GitHub.

## 🚀 Quick Start

```bash
# 1. Fork the repo on GitHub
# 2. Clone your fork
git clone https://github.com/<your-username>/matlab-github-demo.git
cd matlab-github-demo

# 3. Create a feature branch
git checkout -b feature/my-improvement

# 4. Open MATLAB, navigate to the project root
#    startup.m will auto-configure paths

# 5. Make your changes, then run tests
#    >> runAllTests

# 6. Commit and push
git add .
git commit -m "feat: describe your change"
git push -u origin feature/my-improvement

# 7. Open a Pull Request on GitHub
```

## 📋 Guidelines

### Code Style
- Use **camelCase** for function and variable names
- Every function must have a **help block** (`%FUNCTIONNAME  description`)
- Use MATLAB **argument validation blocks** for input checking
- Keep functions **short and focused** (< 80 lines ideally)

### Testing
- Every new function in `src/` must have a corresponding test in `tests/`
- Tests use `matlab.unittest.TestCase`
- Run `runAllTests` before committing — all tests must pass

### Commits
- Use [Conventional Commits](https://www.conventionalcommits.org/)
- Keep commits small and atomic
- Reference issue numbers when applicable: `fix: correct FFT scaling (#12)`

### Pull Requests
- PRs should target the `main` branch
- Include a clear description of **what** and **why**
- Ensure all tests pass
- Request a review from at least one team member

## 🐛 Reporting Issues

Use [GitHub Issues](../../issues) with:
- A clear title
- Steps to reproduce
- Expected vs. actual behaviour
- MATLAB version and OS
