# Live camera translation

Tap **Camera** in the Translate tab to replace the input card with a live rear-camera preview. Hold words or a sentence steady; recognized text appears over the preview and is translated automatically into the selected output language. **Back to typing** closes the camera and keeps the last recognized text available for editing.

The camera scans at most once every 650 ms, waits for two matching OCR samples, and suppresses repeated text. Translation requests run one at a time; newer readings replace pending readings, and obsolete responses are ignored. Input remains limited to 500 characters. Successful translations use the existing history and favorites flow.

Leaving the Translate tab or backgrounding the app closes the camera. Reopen it with **Camera** when returning. Android camera permission and the existing iOS camera usage description are required. This feature uses `camera_android` for Android NV21 frames and BGRA8888 frames on iOS, following the [ML Kit image-input guidance](https://pub.dev/packages/google_mlkit_commons).

Fully restart/rebuild the app after adding the native camera dependencies; hot reload is insufficient. Use the existing `TRANSLATE_API_KEY` build definition. OCR runs on-device; translation still requires network access and the configured Google Translation API key.

## Physical-device checks

- Allow camera access: preview fills the input card without a shutter or image picker.
- Hold a printed sentence steady: detected text and output update automatically.
- Move to another sentence: the latest stable sentence replaces the output.
- Keep the same sentence visible: it does not repeatedly translate or save history.
- Change the source/target language while a request is pending: only the new pair's result appears.
- Deny camera permission: an explanation and close button remain available.
- Close the camera, switch tabs, or background the app: camera access stops.
- Disable connectivity: translation failure offers retry; the preview remains available.
- Check portrait and landscape orientation on both Android and iOS.

Automated coverage checks OCR stability/duplicate filtering and unsupported-platform UI. It does not replace physical-device testing of camera frames, permissions, OCR accuracy, or live API responses.
