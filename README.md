# mobile

## Android APK for testing

When no release-signing credentials are configured, the Android release build
uses the local debug keystore automatically. This is suitable for testing or
sharing an unpublished APK, but not for publishing on Google Play. Build with:

```powershell
shorebird release android --artifact apk
```

Before publishing on Google Play, configure a private release keystore using the
`RELEASE_STORE_FILE`, `RELEASE_STORE_PASSWORD`, `RELEASE_KEY_ALIAS`, and
`RELEASE_KEY_PASSWORD` Gradle properties or environment variables. Keep the
keystore and passwords secure and backed up; future updates must use the same key.
