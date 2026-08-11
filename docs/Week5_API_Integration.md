# Week 5 — API Integration & HTTP Requests
## Language Bridge (Flutter) — API Documentation

**Feature added this week:** live text translation for Philippine languages,
powered by a public web API. (A second API — ElevenLabs Text-to-Speech — was
also integrated for dialect audio; it is summarized at the end.)

---

## 1. API Name

**Google Cloud Translation API (v2 — Basic)**

Google's translation service is the only major engine that supports Philippine
regional languages (Cebuano, Ilocano, Hiligaynon, Waray) in addition to
Filipino/Tagalog, which makes it the right choice for Language Bridge.

## 2. API Endpoint(s) Used

A single **HTTP GET** request to the `translate` endpoint:

```
GET https://translation.googleapis.com/language/translate/v2
      ?key=<API_KEY>
      &q=<text to translate>
      &source=<from language code>
      &target=<to language code>
      &format=text
```

**Example request** (English → Cebuano):

```
GET https://translation.googleapis.com/language/translate/v2
      ?key=****&q=Good%20morning,%20how%20are%20you%3F&source=en&target=ceb&format=text
```

Language codes used by the app (Google codes): `en` (English), `tl` (Filipino),
`ceb` (Cebuano), `ilo` (Ilocano), `hil` (Hiligaynon), `war` (Waray).

## 3. Sample JSON Response

**Real response** for English → Cebuano ("Good morning, how are you?"):

```json
{
  "data": {
    "translations": [
      {
        "translatedText": "Maayong buntag, kumusta ka?"
      }
    ]
  }
}
```

The app reads the value at `data.translations[0].translatedText`.

Actual results returned by the API for the same English input across languages:

| Target | `translatedText` |
|--------|------------------|
| Cebuano (`ceb`) | Maayong buntag, kumusta ka? |
| Ilocano (`ilo`) | Naimbag nga bigat, kumusta ka? |
| Hiligaynon (`hil`) | Maayong aga, kamusta ka? |
| Waray (`war`) | Maupay nga aga, kumusta kamo? |
| Filipino (`tl`) | Magandang umaga, kumusta ka? |

**Sample error response** (e.g., key not allowed / billing off) — handled
gracefully by the app:

```json
{
  "error": {
    "code": 403,
    "message": "This API method requires billing to be enabled ...",
    "status": "PERMISSION_DENIED"
  }
}
```

## 4. Explanation of Integration

**Files added / changed**

| File | Role |
|------|------|
| `lib/services/translation_api.dart` | **New.** Performs the HTTP GET, parses the JSON, and throws `TranslationException` on any error. |
| `lib/screens/translate_screen.dart` | Calls `TranslationApi.translate()`, shows the result card or an error card with **Retry**. |
| `lib/data/mock_data.dart` | Language list switched to Philippine languages (codes = Google codes). |
| `pubspec.yaml` | Added the `http` package. |

**How the request flows**

1. The user types text, chooses the source/target languages, and taps
   **Translate**.
2. `TranslationApi.translate()` builds the URL and performs an **HTTP GET** using
   `package:http`, with a 15-second timeout.
3. The JSON body is decoded and `data.translations[0].translatedText` is shown in
   the result card.
4. The translation is also saved to Cloud Firestore (`users/{uid}/history`), so it
   appears in the **History** tab and persists across restarts (ties into Week 4).

**Error handling** (invalid response, connection issue, unavailable API) — every
case shows a friendly message plus a **Retry** button:

| Situation | Message shown |
|-----------|---------------|
| No internet | "No internet connection. Check your network and try again." |
| Request timed out | "The translation service did not respond. Please try again." |
| Non-200 HTTP (e.g., 403) | The API's own error message is displayed. |
| Malformed / empty JSON | "Received an invalid response from the server." |

**Security** — the API key is **never hardcoded**. It is supplied at build/run
time and read with `String.fromEnvironment('TRANSLATE_API_KEY')`:

```
flutter run --dart-define=TRANSLATE_API_KEY=YOUR_KEY
```

The key is restricted in Google Cloud Console to the *Cloud Translation API*.

**How the API improves the project**

Language Bridge exists to break language barriers, and its core screen is the
translator. Before this integration the screen used a small hardcoded phrasebook,
so it could only "translate" a handful of canned phrases. Integrating the Google
Cloud Translation API turns it into a **real, working translator**: a user can
type any sentence and get an actual Cebuano, Ilocano, Hiligaynon, Waray, or
Filipino translation. This is the single feature that makes the app genuinely
useful to its target users, and it feeds real data into the Week 4 Firestore
history so past translations are saved and searchable.

## 5. Screenshots

### A. API Request Working

Direct call to the API (from the terminal), showing a successful request and the
JSON response:

```
$ curl -G "https://translation.googleapis.com/language/translate/v2" \
     --data-urlencode "key=****" \
     --data-urlencode "q=Good morning, how are you?" \
     --data-urlencode "source=en" \
     --data-urlencode "target=ceb" \
     --data-urlencode "format=text"

{
  "data": {
    "translations": [
      { "translatedText": "Maayong buntag, kumusta ka?" }
    ]
  }
}
```

> _Insert a screenshot of the above request/response (terminal or Postman)._

### B. Data Displayed in the Project

> _Insert a screenshot of the app's **Translate** screen showing:_
> - Input: "Good morning, how are you?" (English → Cebuano)
> - Result card: **"Maayong buntag, kumusta ka?"** with the **Google Translate** badge
>
> _And a second screenshot of the **History** tab showing the saved translation
> (proof the API data is stored in the Firestore database)._

---

## Appendix — Second API integrated: ElevenLabs Text-to-Speech

To let the app **speak** the dialects (the phone has no on-device Cebuano/Ilocano
voice), a second public API was integrated:

- **API Name:** ElevenLabs Text-to-Speech API
- **Endpoint (HTTP POST):**
  `POST https://api.elevenlabs.io/v1/text-to-speech/{voice_id}`
- **Request body (JSON):**
  ```json
  { "text": "Maayong buntag, kumusta ka?", "model_id": "eleven_multilingual_v2" }
  ```
- **Response:** binary `audio/mpeg` (MP3) which the app plays with `audioplayers`.
- **Integration:** `lib/services/cloud_tts_service.dart`. The "Listen" button uses
  the on-device voice for English/Filipino and ElevenLabs for the dialects. Key
  injected via `--dart-define=ELEVENLABS_API_KEY=...` (never committed).
