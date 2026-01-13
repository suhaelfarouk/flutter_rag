# Kuery App

A Flutter application demonstrating RAG (Retrieval-Augmented Generation) capabilities using LangChain, Pinecone, and OpenAI.

## Features

- PDF document ingestion and text extraction
- Vector embeddings creation using OpenAI
- Vector storage and retrieval using Pinecone
- Natural language Q&A over your documents using LangChain

## Requirements

- Flutter SDK 3.38.6 or later (Dart SDK ^3.10.0)
- Pinecone account with API key
- OpenAI account with API key

## Setup

1. Clone the repository

2. Copy the environment file template and add your API keys:
   ```bash
   cp .env.example .env
   ```

3. Edit `.env` with your credentials:
   ```
   PINECONE_API_KEY=your_pinecone_api_key_here
   PINECONE_ENVIRONMENT=your_pinecone_environment_here
   INDEX_HOST=your_index_host_here
   OPENAI_API_KEY=your_openai_api_key_here
   ```

4. Get dependencies:
   ```bash
   flutter pub get
   ```

5. Generate code (if needed):
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

6. Run the app:
   ```bash
   flutter run
   ```

## Project Structure

- `lib/main.dart` - Application entry point
- `lib/core/config.dart` - Service configuration
- `lib/services/` - API services for Pinecone and LangChain
- `lib/view/` - UI components and state management
- `assets/pdf/` - PDF documents for ingestion

## Dependencies

Key dependencies used in this project:

- **hooks_riverpod** - State management
- **langchain** - LangChain Dart SDK for RAG
- **langchain_openai** - OpenAI integration
- **langchain_pinecone** - Pinecone vector store integration
- **syncfusion_flutter_pdf** - PDF text extraction
- **flutter_dotenv** - Environment variable management
- **dio** - HTTP client

## Building

### Web
```bash
flutter build web --release
```

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

## License

This project is for demonstration purposes.
