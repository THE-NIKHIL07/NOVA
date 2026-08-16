# Nova AI - Next-Gen Real-Time Search & AI Assistant

Nova AI is a modern, high-performance real-time search engine and AI assistant built with Flutter, FastAPI, Groq LLM, and Tavily Web Search. It streams AI responses token-by-token alongside interactive web search citations in a multi-turn conversation feed.

---

## 🚀 Key Features

- 🔍 **Real-Time Web Search**: Retrieves live search citations using Tavily Search API.
- ⚡ **Ultra-Fast AI Responses**: Streams responses word-by-word via Groq LLM (LLaMA 3.3 70B & LLaMA 3.1 8B).
- 📜 **Multi-Turn Chat Feed**: Previous questions and answers stay visible and scrollable throughout the active session.
- ⏹️ **Stop Generation Button**: Cancel ongoing AI response generation mid-stream with a single tap.
- 🛡️ **Graceful Fallbacks**: Automatic model retries and search synthesis fallback so queries never return error screens.
- 📱 **Cross-Platform**: Smooth experience across Web & Android APK.

---

## 💻 Tech Stack

### Frontend (Cross-Platform Flutter)
- **Framework**: Flutter (Dart) - Cross-platform support for Web & Android APK
- **Real-Time Communication**: `web_socket_client` for persistent WebSocket streaming
- **UI Components**: `flutter_markdown` (`MarkdownBody`) for smooth response rendering, `skeletonizer` for loading states, `url_launcher` for external source links
- **Design & Typography**: Custom HSL dark theme with Google Fonts (IBM Plex Mono, Inter)

### Backend (Python FastAPI)
- **Framework**: FastAPI (Asynchronous Python Web Framework)
- **AI Intelligence**: `groq` (AsyncGroq client with multi-model fallback: `llama-3.3-70b-versatile` $\rightarrow$ `llama-3.1-8b-instant`)
- **Real-Time Web Search**: `tavily-python` (Tavily Search API)
- **Web Scraping & Parsing**: `trafilatura` for clean content extraction
- **Server**: `uvicorn` with WebSocket streaming support

---

## 📁 Project Structure

```
nova/
├── android/                  # Android Native Configuration & Build Files
├── lib/                      # Flutter Application Source Code
│   ├── models/               # Data Models (chat_turn.dart)
│   ├── pages/                # App Screens
│   │   ├── home_page.dart    # Home Screen with Search Input & Branding
│   │   └── chat_page.dart    # Multi-Turn Chat Feed & Streaming Screen
│   ├── services/             # Web & Mobile Service Layer
│   │   └── chat_web_service.dart # WebSocket Client & Reconnection/Stop Handler
│   ├── theme/                # Design System & Custom Palette (colors.dart)
│   └── widgets/              # Reusable UI Widgets
│       ├── answer_section.dart  # Streaming Markdown Answer Renderer
│       ├── chat_turn_widget.dart# Multi-Turn Q&A Card Container
│       ├── search_bar_button.dart# Interactive Pill Action Buttons
│       ├── search_section.dart  # Main Home Search Bar Container
│       ├── side_bar.dart        # Desktop Web Navigation Drawer
│       └── sources_section.dart # Clickable Search Source Cards
├── render.yaml               # Render Blueprint Deployment File
├── pubspec.yaml              # Flutter Dependencies & Package Configuration
└── server/                   # FastAPI Backend Application
    ├── Procfile              # Web Process Configuration
    ├── config.py             # Pydantic Settings & Environment Loaders
    ├── main.py               # FastAPI App & WebSocket Connection Endpoint
    ├── models/               # Pydantic Schemas (chat_body.py)
    ├── requirements.txt      # Python Package Dependencies for Deployment
    ├── services/             # Core Backend Services
    │   ├── llm_service.py    # AsyncGroq LLM Streaming & Fallback Logic
    │   └── search_service.py # Tavily Search & Trafilatura Web Extractor
    └── .env                  # Local Environment Variables (API Keys)
```

---

## 🛠️ Local Development & Setup

### 1. Backend Setup

1. Navigate to the `server` directory:
   ```bash
   cd server
   ```

2. Create a virtual environment and install dependencies:
   ```bash
   python -m venv venv
   # Windows:
   venv\Scripts\activate
   # macOS/Linux:
   source venv/bin/activate

   pip install -r requirements.txt
   ```

3. Create a `.env` file inside `server/`:
   ```env
   GROQ_API_KEY=your_groq_api_key_here
   TAVILY_API_KEY=your_tavily_api_key_here
   ```

4. Start the server:
   ```bash
   uvicorn main:app --host 0.0.0.0 --port 8000 --reload
   ```

---

### 2. Frontend Setup (Flutter Web & Mobile)

1. Get Flutter dependencies:
   ```bash
   flutter pub get
   ```

2. Run on Web:
   ```bash
   flutter run -d chrome
   ```

3. Build Android APK:
   ```bash
   flutter build apk --release
   ```
   The generated APK will be placed at `build/app/outputs/flutter-apk/app-release.apk`.
