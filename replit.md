# KM$ - Driver Finance Management App

## Overview
KM$ is a mobile application developed in Flutter/Dart, designed to help ride-share drivers efficiently manage their earnings, expenses, and vehicle maintenance. This project aims to provide a native Android application that replaces previous Python/Streamlit dependencies, offering a streamlined and intuitive user experience. The business vision is to empower drivers with comprehensive financial control, improving their profitability and operational efficiency.

## User Preferences
- **Economy of credits**: Prioritize efficiency, avoid unnecessary operations
- **Established infrastructure**: Backend on Fly.io, compiled Flutter app, Supabase active
- **Manual flow**: Builds via Codemagic by the user, not by the agent
- **Communication**: Brazilian Portuguese, mandatory queries before actions
- **Monitoring**: Follow backend logs during app tests
- **Clean project**: Cache removed, unnecessary workflows eliminated
- **Dynamic Configuration**: Preference for flexibility in backend switching without app rebuilds
- **Development Helper Functions**: Request for tools to aid app development and testing

## System Architecture

### Core Technologies
- **Flutter 3.0+** and **Dart** as the primary development framework and language.
- **SQLite** for local data storage with advanced sync capabilities.
- **FL Chart** for interactive data visualization.
- **Material Design 3** for UI/UX, supporting light and dark modes, and responsiveness.
- **Advanced Security System** with input validation, sanitization, and conflict resolution.
- **Bi-directional Sync** with intelligent conflict detection and resolution strategies.

### Project Structure (Monorepo)
The project follows a monorepo structure, separating the frontend Flutter application from a Dart backend API (used for premium features).
```
motouber/
├── frontend/                     # Flutter Application
│   ├── lib/                      # Dart code (main, models, services, screens, theme)
│   │   ├── models/               # Data models (trabalho, gasto, manutencao, user)
│   │   ├── services/             # Business logic services
│   │   ├── screens/              # UI screens
│   │   ├── widgets/              # Reusable UI components
│   │   └── theme/                # App theming
│   ├── android/                  # Android configurations
│   ├── assets/                   # Resources (images, icons)
│   ├── test/                     # Unit tests
│   └── pubspec.yaml              # Flutter dependencies
├── backend/                      # Dart API (Shelf framework)
│   ├── bin/                      # Server entry point
│   ├── lib/                      # API source code
│   │   ├── routes/               # API endpoints
│   │   ├── models/               # Data models
│   │   ├── services/             # Business services
│   │   └── middleware/           # HTTP middleware
│   ├── sql/                      # Database schemas
│   ├── scripts/                  # Database utilities
│   ├── fly.toml                  # Fly.io deployment config
│   └── pubspec.yaml              # Dart dependencies
├── codemagic.yaml                # CI/CD configuration
├── README.md                     # Project documentation
└── replit.md                     # Development notesmentation
└── replit.md                    # Technical history
```

### Key Features
- **Home Screen**: Dashboard with daily/monthly metrics, navigation cards, and latest records.
- **Integrated Daily Log**: Unified form for work, expenses, and maintenance entries. Fuel expenses are now categorized under general expenses. Allows optional addition of expenses/maintenance within the same log.
- **Expense Control**: Categorization, historical data with filters, summary by category, and distribution graphs.
- **Maintenance Management**: Configurable maintenance intervals per type, intelligent default intervals for new types, dynamic alerts based on custom intervals, and detailed history.
- **Reports**: Graphs for earnings over time, profitability analysis, and performance metrics with period selection.
- **Settings**: Category management, local backup/restore, and app information. Advanced settings include maintenance interval configuration.

### Database Schema
Local SQLite database includes `trabalho` (daily work), `gastos` (categorized expenses), `manutencoes` (performed maintenance), and `config` (user settings). Data is stored with unique UUIDs, ISO 8601 dates, decimal values, and descriptions. **CRITICAL**: All models now synchronized between Backend, Frontend, and Supabase with consistent field names and types.

### Security & Synchronization (NEW)
- **Input Validation**: All user inputs are validated and sanitized using `SecurityService`
- **Conflict Resolution**: Intelligent conflict detection and resolution using `ConflictResolutionService`
- **Rate Limiting**: API requests are rate-limited to prevent abuse
- **SQL Injection Prevention**: Advanced middleware to detect and block malicious inputs
- **Bi-directional Sync**: Real-time synchronization between local SQLite and Supabase PostgreSQL
- **Audit Logging**: All critical operations are logged for security monitoring

### Build and Deployment
Development is conducted in Replit, with builds managed manually by the user via Codemagic CI/CD. The application targets Android, with optimized builds for production.

### Design and UX
The application uses a custom theme with primary colors (Blue #1E88E5, Green #26A69A) and adheres to Material Design 3 guidelines. It features intuitive navigation with tabs, floating action buttons, and validated forms.

## External Dependencies

- **Supabase**: Used for backend database (PostgreSQL) and authentication. Tables include `users`, `trabalhos`, `gastos`, and `manutencoes`.
- **Fly.io**: Production backend deployment platform (https://moto.fly.dev).
- **Codemagic**: CI/CD platform for automated APK builds.
- **Shelf**: Dart HTTP server framework for the backend API.

## Recent Changes (August 2025)

### Sistema de Configuração Dinâmica do Backend (August 2, 2025)
- ✅ **Configuração Dinâmica Implementada**: Sistema completo para alterar backend sem recompilação
  - Modelo `BackendConfig` com configurações pré-definidas (Replit, localhost, Fly.io)
  - Serviço `BackendConfigService` com SharedPreferences para persistência
  - Tela de configuração com validação, teste de conexão e presets
  - Verificação de setup inicial no `main.dart`
  - Gesto secreto (5 toques no título) para acesso às configurações de desenvolvimento
- ✅ **Backend URLs Dinâmicas**: Todas as chamadas HTTP do ApiService agora usam configuração dinâmica
  - URLs construídas dinamicamente baseadas na configuração atual
  - Timeout configurável por backend
  - Suporte a HTTP e HTTPS
  - Teste de conectividade integrado
- ✅ **Backend Replit**: Ainda funcionando na porta 5000 com acesso externo
  - URL pública: `https://6d6e54df-ff6d-4db5-89c0-f44cf71804ff-00-udgvjocecjan.janeway.replit.dev`
  - Configuração padrão quando app inicia pela primeira vez
  - CORS completo e endpoints funcionais

## Recent Changes (August 2025)

### Code Cleanup Performed
- ✅ Removed duplicate and unnecessary files:
  - `main_minimal.dart` (redundant test file)
  - Multiple `.env` example files
  - Python dependencies (`pyproject.toml`, `uv.lock`)
  - Duplicate documentation files
  - Redundant SQL scripts
  - Temporary and backup files
- ✅ Cleaned up `.gitignore` to remove Python-specific entries
- ✅ Updated documentation to reflect current Dart backend implementation
- ✅ Consolidated project structure documentation
- ✅ Removed duplicate README files between root and backend folders

### Current Project State
- **Frontend**: Flutter app with comprehensive financial tracking
- **Backend**: Dart/Shelf API deployed on Fly.io
- **Database**: Supabase PostgreSQL with proper RLS policies
- **Authentication**: JWT-based with Supabase integration
- **CI/CD**: Codemagic for Android APK builds
- **Development**: Optimized for Replit development environmentnd API.
- **shelf**: Dart web server framework used for the backend API.