# REGRAS DO USUÁRIO - OBRIGATÓRIAS PARA TODOS OS AGENTES

1. **Seja direto e objetivo** - Responda de forma breve. Quando possível, use apenas "Sim" ou "Não"

2. **Faça apenas o que foi pedido** - Nada além do solicitado

3. **Não faça nada além do que foi pedido** - Sem iniciativas extras

4. **Em caso de dúvida, pergunte** - Sempre pare e pergunte, mesmo que ache que entendeu

5. **Flutter não roda aqui** - Projetos Flutter NÃO podem ser executados no Replit. Build é feito via Codemagic (usuário faz via `git add .` e `git push`)

6. **Backend roda aqui** - Backend Dart/Shelf executa no Replit para análise e testes com banco de dados

7. **SUPABASE NÃO VAI SER USADO** - usar banco de dados no backend 








KM$ (Motora) - Aplicativo de Controle Financeiro

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
-trabalhando... mas sera dentro do backend.

## Configuração e Execução

### Backend
```bash
cd backend
dart pub get
PORT=5000 dart run bin/server.dart
```

### Frontend
`` vai ser compilado no codemagic isso o usuário vai fazer manual.
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

## 