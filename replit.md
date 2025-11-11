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
- **Backend**: Dart com Shelf framework (porta 5000)
- **Banco de Dados**: SQLite no backend (km_dollar.db)
- **Estratégia**: Login obrigatório + transmissão em tempo real + isolamento por user_id

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
- **SQLite no backend** (`km_dollar.db`)
- **Tabelas**: users, trabalho, gastos, manutencao
- **Isolamento**: Todos os registros filtrados por `user_id`
- **Segurança**: DELETE/UPDATE validam propriedade do registro (retornam 404 se não pertencer ao usuário)

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
- Transmissão em tempo real para backend (OnlineDataService)
- Dados sincronizados a cada ação do usuário

## Tema "Grau 244"
Interface moderna com estética jovem motociclista:
- Gradientes neutros (cinzas, pretos, brancos)
- Material Design 3
- Cores de destaque para ações importantes
- Design limpo e intuitivo

## Segurança
- **Login obrigatório** (estilo Facebook)
- **JWT** com refresh tokens
- **Senhas hasheadas** (bcrypt)
- **Isolamento de dados**: WHERE user_id = ? em todas as queries
- **Validação de propriedade**: DELETE/UPDATE verificam se registro pertence ao usuário (SELECT changes())
- **Multi-window Android**: Habilitado via android:resizeableActivity="true" na <activity>

## CI/CD
- **Plataforma**: Codemagic
- **Target**: Android APK
- **Configuração**: `codemagic.yaml`

---

## 🔧 PROBLEMAS IDENTIFICADOS E CORREÇÕES NECESSÁRIAS (11/11/2025)

### 🔴 PROBLEMAS CRÍTICOS

#### 1. Botão "Limpar Todos os Dados" NÃO FUNCIONA
- **Arquivo:** `frontend/lib/screens/configuracoes_screen.dart` (linha 724-739)
- **Problema:** Mostra mensagem de sucesso mas NÃO chama `DatabaseService.clearAllData()`
- **Ação:** Implementar limpeza real do banco + logout + alerta de risco

#### 2. Tipos de Manutenção VAZIOS na primeira instalação
- **Arquivo:** `frontend/lib/services/database_service.dart`
- **Problema:** Intervalos são inseridos mas tipos NÃO
- **Ação:** Inicializar tipos padrão (Troca de óleo, Revisão geral, Pneus, etc) na criação do banco

#### 3. Categorias de Gastos NÃO inicializam
- **Arquivo:** `frontend/lib/services/database_service.dart` + `constants/categories.dart`
- **Problema:** Constantes existem mas não são inseridas no banco
- **Ação:** Inserir categorias padrão (Combustível, Alimentação, Pedágio, etc) na criação do banco

#### 4. Dados locais permanecem após logout
- **Arquivo:** `frontend/lib/services/auth_service.dart` (linha 65-67)
- **Problema:** Logout só remove token, SQLite continua com dados
- **Ação:** Chamar `DatabaseService.clearAllData()` no logout

### 🗑️ BOTÕES DESNECESSÁRIOS (POLUIÇÃO DE UI)

| Item | Arquivo | Ação |
|------|---------|------|
| Menu "Sincronizar" | `home_screen.dart` linha 176-184 | REMOVER |
| "Backup na Nuvem" | `configuracoes_screen.dart` linha 430-436 | REMOVER |
| "Compartilhar Backup" | `configuracoes_screen.dart` linha 648-652 | REMOVER |
| Tela SyncScreen inteira | `sync_screen.dart` + `main.dart` rota | DELETAR |
| "Limpar Cache" (fake) | `configuracoes_screen.dart` linha 461-467 | REMOVER |
| Tab "Backup" completa | `configuracoes_screen.dart` linha 615-694 | REMOVER |

### 🧹 CÓDIGO LIXO

- **TODOs não implementados:**
  - `sync_service.dart` linha 231-233
  - `premium_screen.dart` linha 337
- **Funções fake:**
  - `_clearCache()` - apenas delay sem ação
  - `_clearAllData()` - não limpa nada

### ✅ PLANO DE CORREÇÃO

1. ✅ Inicializar categorias de gastos padrão
2. ✅ Inicializar tipos de manutenção padrão
3. ✅ Corrigir botão "Limpar Todos os Dados"
4. ✅ Limpar dados locais no logout
5. ✅ Remover botões/telas de sincronização
6. ✅ Remover tab Backup das configurações
7. ✅ Limpar código fake/inútil

## 