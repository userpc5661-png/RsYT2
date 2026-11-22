# RS Insta

**RS Insta** is now based on the real source code of **Sparkle for Instagram**, rather than the earlier small proof-of-concept tweak. The upstream feature source, settings screens and resources are imported into [RSInstaSparkle/](RSInstaSparkle/) under **GNU GPLv3**. Original project and authors: [Scythe101/sparkle-ig](https://github.com/Scythe101/sparkle-ig), with upstream authorship recorded in [RSINSTA_UPSTREAM.md](RSInstaSparkle/RSINSTA_UPSTREAM.md).

## Current source of truth

- [Full Sparkle-derived RS Insta source](RSInstaSparkle/)
- [Original feature documentation](RSInstaSparkle/FEATURES.md)
- [Real settings screen source](RSInstaSparkle/src/Settings/SPKSettingsViewController.m)
- [Build RS Insta from Sparkle source](.github/workflows/build-rsinsta-sparkle.yml)
- [Download generated RSInsta.dylib / rootless DEB](../../actions/workflows/build-rsinsta-sparkle.yml)

The old `src/RSInsta.m` and `build.yml` are kept as legacy prototypes, **not** the primary RS Insta code. Do not mistake their small generated dylib for the new Sparkle-derived version.

## Changes from upstream

RS Insta has its own build target `RSInsta.dylib`, package identifier `com.rsinsta.tweak`, package name `RS Insta`, and a few localized title changes. We preserve internal `SPK` classes, preferences, resource names and selectors where changing them could break features. The original Sparkle layout and feature code remain intact.

This does not imply every feature has been verified on your Instagram and iOS versions. User testing is required. The required FFmpegKit and Theos toolchain are configured in the new GitHub Actions workflow.

## GPLv3 license and credit

Modifications and redistributions are licensed under GPLv3 with the corresponding source available. Keep upstream copyright notices and license intact. Do not import proprietary Beegram binaries or sensitive user data.
