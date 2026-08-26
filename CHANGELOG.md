# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial project structure
- Idempotent installation tracking with manifest system
- DLC detection and automatic installation
- Wine prefix initialization
- Interactive installer confirmation
- Comprehensive logging
- Status reporting and dry-run mode
- GitHub Actions release automation

### Changed

### Deprecated

### Removed

### Fixed

### Security

---

## Format Notes

When creating new releases, use the following sections:

- **Added** for new features
- **Changed** for changes in existing functionality
- **Deprecated** for soon-to-be removed features
- **Removed** for now removed features
- **Fixed** for any bug fixes
- **Security** for vulnerability fixes

## How to Create a Release (Maintainers Only)

1. Merge all desired changes to the main branch via pull requests
2. Update this file with a new version section under an appropriate version heading
3. Commit your changes: `git add CHANGELOG.md && git commit -m "Release: version X.Y.Z"`
4. Create a git tag: `git tag v1.0.0`
5. Push to the repository: `git push origin main && git push origin v1.0.0`
6. GitHub Actions automatically creates the release with all assets

> Only maintainers have permission to push tags and create releases.

Example entry:

```markdown
## [1.0.0] - 2024-08-26

### Added
- Feature X
- Feature Y

### Fixed
- Bug fix A
```
