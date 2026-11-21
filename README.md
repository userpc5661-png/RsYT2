# RS Insta

Independent Objective-C iOS tweak project. This repository does **not** contain or redistribute the reference proprietary binary.

## Current feature status

- **Implemented as experimental hooks, not tested on a device:** hide story seen, suppress one direct-read update path, screenshot-blocking guard.
- **Implemented locally:** RS launcher, grouped settings menu, persisted toggles, optional media-URL downloader/share sheet.
- **Not implemented:** the remaining advertised reference features. The menu clearly marks these as unavailable rather than pretending they work.

This is **not** a 100%-complete reconstruction. The project is designed for user-led device tests, where unsupported Instagram versions may lack target classes/methods.

## Build

See `.github/workflows/build.yml` for a GitHub Actions macOS/iPhoneOS SDK build. A successful build means the output is an ARM64 iOS Mach-O dynamic library; it does **not** verify injection or runtime feature compatibility. Download the `RSInsta-dylib` workflow artifact from GitHub Actions after a successful run.

## Test

`python3 tests/test_source.py`

Do not publish secrets, user accounts, session cookies, or the reference binary in issues or commits.
