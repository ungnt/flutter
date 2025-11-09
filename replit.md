# KM$ (Motouber) - Aplicativo de Controle Financeiro

## Visão Geral
Aplicativo de controle financeiro desenvolvido em Flutter, voltado para motoristas de aplicativo e motociclistas. Oferece gestão completa de ganhos, gastos e manutenções do veículo, com funcionalidades de relatórios, metas, backup local/nuvem e sincronização multi-dispositivo.

## Arquitetura
- **Frontend**: Flutter (Android/iOS/Desktop)
- **Backend**: Dart com Shelf framework
- **Banco de Dados**: SQLite local + Supabase PostgreSQL (sincronização)
- **Estratégia**: Offline-first com sync opcional para nuvem

## Estrutura do Projeto

### Frontend (`/frontend`)
- **Linguagem**: Dart/Flutter
- **Banco Local**: SQLite (sqflite)
- **Features Principais**:
  - Registro de trabalhos (corridas/entregas)
  - Controle de gastos categorizados
  - Gestão de manutenções com intervalos configuráveis
  - Sistema de metas e objetivos
  - Relatórios e estatísticas
  - Backup local e compartilhamento
  - Sincronização com nuvem

### Backend (`/backend`)
- **Linguagem**: Dart
- **Framework**: Shelf
- **Porta**: 5000
- **Dependências**:
  - shelf: ^1.4.1 (servidor HTTP)
  - shelf_router: ^1.1.4 (roteamento)
  - shelf_cors_headers: ^0.1.5 (CORS)
  - dotenv: ^4.2.0 (variáveis de ambiente)
  - logging: ^1.2.0 (logs)
  - supabase: ^2.0.0 (cliente Supabase)
  - crypto: ^3.0.3 (criptografia)
  - dart_jsonwebtoken: ^2.13.0 (autenticação JWT)

### Banco de Dados
- **Local**: SQLite com tabelas:
  - trabalhos (corridas/entregas)
  - gastos (combustível, alimentação, manutenção, etc)
  - manutencoes (óleo, pneus, freios, etc)
  - categorias_gastos (personalizáveis)
  - categorias_manutencao (personalizáveis)
  - metas (objetivos diários/mensais)

- **Nuvem**: Supabase PostgreSQL
  - users (autenticação)
  - sync_data (dados sincronizados)
  - RLS (Row Level Security) habilitado

## Configuração e Execução

### Backend
```bash
cd backend
dart pub get
PORT=5000 dart run bin/server.dart
```

### Frontend
```bash
cd frontend
flutter pub get
flutter run
```

## Funcionalidades Principais

### 1. Registro de Trabalhos
- Data, hora, valor ganho
- Km inicial e final
- Tipo de serviço (app de transporte)
- Observações opcionais

### 2. Controle de Gastos
- Categorização customizável
- Valores e datas
- Vinculação opcional a trabalhos
- Relatórios por período

### 3. Gestão de Manutenções
- Tipos: óleo, pneus, freios, corrente, etc.
- Intervalos configuráveis (km ou dias)
- Alertas de vencimento
- Histórico completo

### 4. Metas e Objetivos
- Metas diárias e mensais
- Eficiência de combustível
- Progresso em tempo real
- Estatísticas de desempenho

### 5. Backup e Sincronização
- Backup local (JSON)
- Compartilhamento via share
- Sync com nuvem (Supabase)
- Resolução de conflitos

## Tema "Grau 244"
Interface moderna com estética jovem motociclista:
- Gradientes neutros (cinzas, pretos, brancos)
- Material Design 3
- Cores de destaque para ações importantes
- Design limpo e intuitivo

## Segurança
- Autenticação JWT com refresh tokens
- Senhas hasheadas (bcrypt)
- Row Level Security no Supabase
- HTTPS obrigatório para comunicação
- Variáveis de ambiente para secrets

## CI/CD
- **Plataforma**: Codemagic
- **Target**: Android APK
- **Configuração**: `codemagic.yaml`

## Mudanças Recentes

### 2025-11-09
- ✅ Criado arquivo `backend/pubspec.yaml` com todas as dependências necessárias
- ✅ Instaladas dependências do backend Dart
- ✅ Backend inicializado e rodando na porta 5000
- ✅ Conexão com Supabase estabelecida
- ✅ Servidor respondendo corretamente aos health checks

## Variáveis de Ambiente Necessárias

### Backend
```env
SUPABASE_URL=sua_url_supabase
SUPABASE_ANON_KEY=sua_chave_anonima
JWT_SECRET=seu_jwt_secret_seguro
PORT=5000
HOST=0.0.0.0
```

## Próximos Passos Potenciais
- Implementar testes unitários e de integração
- Adicionar notificações push
- Implementar dark mode completo
- Adicionar exportação de relatórios (PDF)
- Implementar sistema de backup automático
- Adicionar suporte para múltiplos veículos

## Observações Técnicas
- O projeto usa arquitetura offline-first, garantindo funcionalidade sem internet
- O sync com nuvem é opcional e configurável pelo usuário
- Todas as operações críticas são validadas antes de serem enviadas ao backend
- Sistema de resolução de conflitos implementado para dados sincronizados
- Backend configurável com URLs dinâmicas (Replit, localhost, Fly.io)

## Preferências do Usuário
- Foco em funcionalidade offline-first
- Design jovem e moderno (tema "Grau 244")
- Priorizar performance e experiência do usuário
- Manter código organizado e bem documentado
