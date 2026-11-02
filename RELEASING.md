# Releasing Cat Spotter

Releases are signed APKs published on [GitHub Releases](https://github.com/gregor2018github/ProjectCatSpotter/releases) for sideloading. There is no Play Store build.

## Cutting a release

```bash
git checkout master && git pull
git tag v1.2.0
git push --tags
```

The tag push starts `.github/workflows/release.yml`, which:

1. Derives the version from the tag: `versionName` = `1.2.0`, `versionCode` = `major*10000 + minor*100 + patch` (here `10200`).
2. Builds a signed APK with `flutter build apk --release`, which runs Gradle `assembleRelease`.
3. Verifies the signature with `apksigner`.
4. Creates a GitHub Release named after the tag, attaches `cat-spotter-1.2.0.apk` and generates the release notes automatically.

Rules for tags:
- Tags must be `vX.Y.Z`; anything else fails the build.
- Always use a higher version than the last release. Android refuses to install an update with a lower `versionCode`.
- Keep minor and patch below 100, so that `versionCode` keeps increasing.

If a release build fails, fix the problem, then delete the tag and push it again:

```bash
git tag -d v1.2.0 && git push origin :refs/tags/v1.2.0
git tag v1.2.0 && git push --tags
```

## Signing

| What | Where |
|---|---|
| Keystore | `C:\Users\kraus\keystores\cat-spotter-release.jks` (outside the repo) |
| Alias | `release` |
| Passwords, path and alias | `cat_spotter/android/keystore.properties` (git-ignored) |
| CI copies | Repository secrets `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD` |

`android/app/build.gradle.kts` reads `keystore.properties` when it exists. Otherwise it reads the environment variables listed above. On a local machine with neither, release builds are signed with the debug key. In CI (`CI` is set), a missing keystore fails the build.

To build a signed APK locally:

```bash
cd cat_spotter
flutter build apk --release
```

To rotate the CI secrets, for example after moving to a new machine:

```bash
base64 -w0 ~/keystores/cat-spotter-release.jks | gh secret set KEYSTORE_BASE64
gh secret set KEYSTORE_PASSWORD   # paste when prompted
gh secret set KEY_ALIAS           # release
gh secret set KEY_PASSWORD        # paste when prompted
```

## Back these up

You can't recover from losing them. Store **both** somewhere safe outside this PC, such as a password manager:

1. `cat-spotter-release.jks` (the keystore file)
2. The contents of `keystore.properties` (the store and key passwords)

Every future update must be signed with the same key. Without it, friends would have to uninstall the app before installing a new version, and **uninstalling deletes all their cats and sightings**. GitHub secrets can't be read back, so they don't count as a backup.
