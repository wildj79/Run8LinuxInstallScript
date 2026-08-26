# Contributing to Run 8 V3 Wine Installer

Thank you for your interest in contributing! This document provides guidelines for reporting issues, suggesting features, and submitting code.

## Getting Started

1. **Fork the repository** on GitHub
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/your-username/Run8Installer.git
   cd Run8Installer
   ```
3. **Create a branch** for your changes:
   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/your-bug-fix
   ```

## Testing Changes

Before submitting a PR, test your changes thoroughly:

```bash
# Test basic installation
./install-run8.sh

# Test status reporting
./install-run8.sh --status

# Test dry-run mode
./install-run8.sh --dry-run

# Test with custom paths
RUN8_ROOT=/tmp/test-run8 ./install-run8.sh --dry-run
```

## Code Style

- Use 4-space indentation
- Follow existing code conventions
- Add comments for complex logic
- Ensure the script is idempotent (safe to run multiple times)
- Test with both Bash 4.0+ and modern versions

## Submitting Changes

1. **Commit your changes** with clear messages:
   ```bash
   git commit -m "Fix: correct Wine prefix initialization"
   ```
2. **Push to your fork**:
   ```bash
   git push origin feature/your-feature-name
   ```
3. **Create a Pull Request** on GitHub using the PR template

## Creating Releases

> **Note**: Only maintainers can create releases. If you'd like to become a trusted contributor with release permissions, please open a discussion with the maintainers.

Releases are automated via GitHub Actions. The maintainers create releases by following this process:

### 1. Review and Merge Contributions

Contributors submit PRs with their changes. The maintainer:
- Reviews the code for quality and idempotency
- Tests thoroughly with `./install-run8.sh --dry-run`
- Merges approved PRs to the main branch

### 2. Update CHANGELOG.md

Before creating a release, update [CHANGELOG.md](CHANGELOG.md) with:
- New version number (using [semantic versioning](https://semver.org/))
- Date
- Sections: Added, Changed, Fixed, etc.
- Summary of all changes since the last release

### 3. Commit and Create a Git Tag

The maintainer creates a release by:

```bash
# Commit the changelog update
git add CHANGELOG.md
git commit -m "Release: version X.Y.Z"

# Create a semantic version tag
git tag v1.0.0

# Push to main repository (requires maintainer permissions)
git push origin main
git push origin v1.0.0
```

### 4. GitHub Actions Handles the Rest

When a tag matching `v*.*.*` is pushed, the GitHub Actions workflow automatically:

- Creates a GitHub Release
- Generates release notes from commit history
- Packages the script into `.tar.gz` and `.zip` archives
- Includes the raw script for direct download
- Attaches all files to the release

### Release Versioning

Follow [semantic versioning](https://semver.org/):

- **Major** (e.g., `v2.0.0`): Breaking changes, major rewrites
- **Minor** (e.g., `v1.1.0`): New features, backward compatible
- **Patch** (e.g., `v1.0.1`): Bug fixes, minor improvements

## Reporting Issues

Use the appropriate issue template when reporting bugs or requesting features:

- **Bug Report**: Use for problems with the script
- **Feature Request**: Use for enhancement suggestions
- **Installation Help**: Use for usage questions

Include:
- Clear description of the issue
- Steps to reproduce (for bugs)
- Environment details (OS, Wine version, Bash version)
- Relevant log output from `install.log`

## Reporting Security Issues

If you discover a security vulnerability, please email security details privately rather than using the issue tracker.

## License

By contributing, you agree that your contributions will be licensed under the same license as the project.

## Questions?

Feel free to open an issue with the "help" label for questions about the project.
