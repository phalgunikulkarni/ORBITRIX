This project uses Google Maps. To avoid committing API keys, add the Maps API key locally and inject it into Android manifest using Gradle placeholders.

1) Add your Maps key to `local.properties` (DO NOT commit this file):

MAPS_API_KEY=AIza...your_key_here

2) Ensure `android/app/build.gradle.kts` adds the manifest placeholder `MAPS_API_KEY` from `local.properties` (example provided below).

3) In `AndroidManifest.xml` add:

<meta-data android:name="com.google.android.geo.API_KEY" android:value="${MAPS_API_KEY}" />

4) Restrict the API key in Google Cloud Console (Android package name + SHA-1 fingerprint).

If you want, I can wire the Gradle Kotlin DSL snippet into `android/app/build.gradle.kts` automatically and add the manifest meta-data placeholder to the manifest file for you. Otherwise, add the key locally and rebuild the app.
