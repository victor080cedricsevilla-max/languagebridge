# Language Bridge: A Mobile Application for Multilingual Communication and Language Learning

## 1. Project Description

Language Bridge is a mobile application designed to help people overcome language barriers through translation and language learning features.

The application allows users to translate text, voice, and images between supported languages. It also provides language learning modules for Philippine languages such as Cebuano, Ilocano, Hiligaynon, and Waray.

Users who want to learn a specific language can select a language module and access lessons covering common words, greetings, daily conversations, pronunciation, and useful expressions.

The application combines translation tools with structured language learning so users can communicate with others while developing their language skills.

## 2. Problem Statement

Language barriers create difficulties in education, tourism, employment, public services, and everyday communication. People who speak different languages often struggle to understand information or communicate their needs effectively.

In the Philippines, language differences also exist between regions. A person who speaks Filipino or Tagalog might have difficulty communicating with someone who primarily speaks Cebuano, Ilocano, Hiligaynon, Waray, or another local language.

Common problems include:

- Difficulty communicating with people who speak different languages
- Difficulty understanding local words and expressions
- Limited access to language learning resources
- Misunderstandings caused by incorrect translations
- Difficulty communicating during travel and everyday interactions

Language Bridge addresses these problems through a combination of translation and language learning features.

## 3. SDG Alignment

**SDG 4: Quality Education**
Language Bridge supports accessible language learning by providing structured lessons, vocabulary, pronunciation guides, and conversations.

The application gives users an accessible way to learn languages outside traditional classroom settings.

**SDG 10: Reduced Inequalities**
Language barriers limit people's access to information and services. Language Bridge helps reduce these barriers by providing translation and communication tools for users from different linguistic backgrounds.

**SDG 16: Peace, Justice and Strong Institutions**
Better communication supports understanding between individuals and communities. Language Bridge helps users communicate more effectively when interacting with people who speak different languages.

**Primary SDG:** SDG 10: Reduced Inequalities

**Supporting SDGs:** SDG 4: Quality Education, SDG 16: Peace, Justice and Strong Institutions

## 4. Objectives

### General Objective

To develop a mobile application that helps users overcome language barriers through real-time translation and accessible language learning modules.

### Specific Objectives — Implemented

1. Develop a mobile application using Flutter and Dart.
2. Provide text translation between supported languages via the Google Cloud Translation API.
3. Provide voice-based translation through on-device Speech-to-Text and Text-to-Speech, with a cloud Text-to-Speech fallback for dialects the device cannot voice natively.
4. Provide image-to-text translation using on-device OCR (Google ML Kit Text Recognition).
5. Provide language learning modules for Philippine languages.
6. Allow users to study vocabulary, phrases, pronunciation, and conversations.
7. Store user translation history, favorite phrases, languages, and lessons using Firebase Cloud Firestore.
8. Implement full CRUD operations (Create, Read, Update, Delete) for history, lessons, and language modules.
9. Implement Firebase Authentication for user registration and login.

### Specific Objectives — Planned (Future Work)

10. Integrate AI (e.g., Google Gemini API) to provide conversational language practice and translation assistance.
11. Provide quizzes and progress tracking for language learners.
12. Implement push notifications via Firebase Cloud Messaging.

## 5. Target Users

The primary users of Language Bridge include:

- Students
- Tourists and travelers
- Teachers and educators
- Foreign visitors
- Workers
- Business professionals
- Individuals learning Philippine languages
- People communicating with speakers of different languages

The application is especially useful for users who frequently interact with people from different linguistic backgrounds.

## 6. Scope

The project covers the development of a Flutter-based mobile application with the following features.

### 6.1 Implemented (Current Build)

**User Management**
- User registration and login (Firebase Authentication)
- User profile (name, email, member-since date)

**Translation**
- Text translation
- Voice translation (on-device Speech-to-Text)
- Image translation (on-device OCR)
- Translation history
- Favorite translations

**Supported Languages**
English, Filipino, Cebuano, Ilocano, Hiligaynon, and Waray — the Philippine languages currently supported by the Google Cloud Translation API (see Limitations, Section 7).

**Language Learning**
- Language module selection
- Vocabulary lessons, common phrases, greetings, daily conversations, and pronunciation notes per module

**Database (Firebase Cloud Firestore)**
Stores languages, lessons, and per-user translation history.

**CRUD Operations**

| Operation | Applies to |
|---|---|
| Create | Add languages, lessons, and translation history entries |
| Read | Display languages, lessons, translation history |
| Update | Modify language/lesson details, favorite status |
| Delete | Remove languages, lessons, and history entries |

### 6.2 Planned (Future Work)

- AI conversation practice and context-based language assistance
- Quizzes and learning progress tracking
- Push notifications (Firebase Cloud Messaging)
- Additional Philippine languages, pending translation API support

## 7. Limitations

The project has the following limitations:

- Translation accuracy depends on the external translation service being used (Google Cloud Translation API).
- Translation and cloud voice features require an internet connection; on-device speech recognition and OCR work offline once the app is installed.
- **The application only supports the Philippine languages currently available through the Google Cloud Translation API — English, Filipino, Cebuano, Ilocano, Hiligaynon, and Waray. Other Philippine languages, such as Kapampangan, cannot be added yet because they are not offered by the translation API being used.** Support for additional languages depends on future API availability.
- Language learning content currently focuses on basic vocabulary, phrases, pronunciation, and conversations; it does not yet include quizzes or progress tracking.
- The application will not replace professional translators or formal language education.
- OCR accuracy depends on image quality, lighting, text clarity, and the languages supported by the on-device recognizer.
- Speech recognition accuracy depends on pronunciation, background noise, microphone quality, and the device's built-in recognizer.
- The application will not provide certified translations for legal, medical, or official documents.
- API usage may be subject to service limits and pricing depending on the provider (Google Cloud Translation, ElevenLabs).
- AI-assisted conversation practice is not yet implemented; it is planned for a future phase.

## 8. Technology Stack

**Frontend**
- Flutter
- Dart

**Backend / Database**
- Firebase Cloud Firestore
- Firebase Authentication

**Translation**
- Google Cloud Translation API

**OCR (image-to-text)**
- Google ML Kit Text Recognition (on-device)

**Voice**
- On-device Speech-to-Text (device recognizer)
- On-device Text-to-Speech (device synthesizer)
- ElevenLabs Text-to-Speech API (cloud fallback for dialect voices the device cannot speak natively)

**Planned / Not Yet Implemented**
- AI conversation assistant (Google Gemini API or equivalent)
- Firebase Cloud Messaging (push notifications)
- Firebase Storage (media uploads)

## 9. Expected Outcome

The expected outcome is a functional mobile application that allows users to translate languages and learn selected Philippine languages through structured modules.

The completed application demonstrates:

- Functional mobile UI
- User authentication
- CRUD operations
- Firebase database integration
- Translation API integration
- HTTP requests to external APIs
- OCR-based image translation
- Voice-based translation
- Language learning modules

Planned for future phases: AI-assisted conversation practice, quizzes, and learning progress tracking.

The project aims to provide users with a practical tool for both immediate communication and long-term language learning.
