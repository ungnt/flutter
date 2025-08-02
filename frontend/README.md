# 📱 KM$ Frontend - App Flutter

## 📋 Sobre

Aplicativo móvel Flutter para controle financeiro de motoristas de aplicativo. Interface moderna com tema neutro e profissional.

## 🎯 Funcionalidades

### ✅ Implementadas
- **Dashboard**: Métricas do dia/mês com cards animados
- **Registro Integrado**: Trabalho + gastos + manutenções em uma tela
- **Sistema de Metas**: Progresso diário, mensal e eficiência
- **Relatórios**: Gráficos interativos com FL Chart
- **Backup Local**: Exportação/importação via JSON
- **Tema Dinâmico**: Modo claro/escuro/automático

### 🔄 Em Desenvolvimento
- **Login/Cadastro**: Integração com backend
- **Backup Nuvem**: Sincronização automática
- **Premium**: Controle de funcionalidades pagas
- **Multi-device**: Sincronização entre dispositivos

## 🏗️ Estrutura Técnica

### Arquitetura
```
lib/
├── main.dart              # Ponto de entrada
├── models/                # Modelos de dados (SQLite)
│   ├── trabalho_model.dart
│   ├── gasto_model.dart
│   └── manutencao_model.dart
├── services/              # Serviços principais
│   ├── database_service.dart
│   ├── goals_service.dart
│   ├── theme_service.dart
│   └── backup_service.dart
├── screens/               # Telas do aplicativo
│   ├── home_screen.dart
│   ├── registro_integrado_screen.dart
│   ├── goals_screen.dart
│   ├── relatorios_screen.dart
│   └── configuracoes_screen.dart
├── widgets/               # Componentes reutilizáveis
│   ├── modern_card.dart
│   ├── animated_counter.dart
│   └── grau_244_header.dart
└── theme/                 # Tema personalizado
    └── app_theme.dart
```

### Tecnologias
- **Flutter 3.24+**
- **SQLite** (via sqflite)
- **Provider** (gestão de estado)
- **FL Chart** (gráficos)
- **Shared Preferences** (configurações)
- **Material Design 3**

## 🎨 Design Neutro

### Conceito Visual
- Interface limpa e profissional
- Cores neutras baseadas no Material Design
- Cards modernos com sombras suaves
- Animações suaves (flutter_staggered_animations)
- Navegação clara e intuitiva

### Paleta de Cores
- **Primária**: Azul #1976D2
- **Secundária**: Cinza #424242
- **Accent**: Azul #2196F3
- **Background**: Tons neutros

## 🚀 Desenvolvimento

### Pré-requisitos
- Flutter SDK 3.24+
- Android SDK 34+
- Dart SDK 3.0+

### Instalação
```bash
cd frontend
flutter pub get
flutter doctor  # verificar configuração
```

### ⚠️ **LIMITAÇÃO CRÍTICA DO REPLIT**
```bash
# ❌ IMPOSSÍVEL NO REPLIT:
# flutter pub get
# flutter run
# flutter build apk

# ✅ PROCESSO OBRIGATÓRIO:
# 1. Editar código no Replit
# 2. Commit e push para GitHub  
# 3. Build automático via Codemagic
# 4. Download APK para teste real
```

### Build APK (Via Codemagic)
```yaml
# ✅ ÚNICO MÉTODO FUNCIONAL:
# codemagic.yaml já configurado
# Trigger: push para main/develop
# Output: APK Android compilado
# Distribuição: Email automático
```

### Teste Local (IMPOSSÍVEL)
```bash
# ❌ Flutter SDK não funciona no Replit
# ❌ Android SDK não disponível
# ❌ Emuladores não suportados

# ✅ ALTERNATIVA:
# Testar apenas via APK em device real
```

## 📦 CI/CD Pipeline

### Codemagic (Atual)
```yaml
# codemagic.yaml - configurado para:
- Build automático no push
- Flutter 3.24.0 específico
- Android SDK 34
- APK release assinado
- Deploy automático via email
```

### Fluxo de Deploy
1. **Desenvolvimento**: Replit
2. **Versionamento**: GitHub (push automático)
3. **Build**: Codemagic (trigger automático)
4. **Distribuição**: APK por email
5. **Futuro**: Google Play Store

## 🗄️ Banco de Dados Local

### Tabelas SQLite
```sql
-- Registros de trabalho diário
trabalho (id, data, ganhos, horas, km, observacoes)

-- Gastos categorizados  
gastos (id, data, categoria, valor, descricao)

-- Manutenções realizadas
manutencoes (id, data, tipo, valor, km, descricao)

-- Configurações do usuário
config (chave, valor)

-- Intervalos de manutenção personalizáveis
intervalos_manutencao (tipo, intervalo_km)
```

### Migrações
- Sistema automático de upgrade do banco
- Compatibilidade com versões anteriores
- Backup antes de migrações críticas

## 🔧 Configurações Especiais

### Android Build
```gradle
// android/app/build.gradle
compileSdk 34
targetSdk 34
minSdk 21

// Arquiteturas suportadas
arm64-v8a, armeabi-v7a
```

### Dependências Temporariamente Removidas
```yaml
# Comentadas para resolver builds
# file_picker: ^8.0.0
# permission_handler: ^11.3.1  
# path_provider: ^2.1.3
# share_plus: ^9.0.0
```

## 🎯 Funcionalidades Premium (Futuras)

### Integração Backend
- **Login/Cadastro** via API REST
- **Status Premium** dinâmico
- **Backup Automático** para nuvem
- **Sincronização** multi-device

### Recursos Exclusivos Premium
- **Relatórios PDF** avançados
- **Dashboard Analytics** 
- **Alertas Inteligentes**
- **Backup Ilimitado**
- **Multi-device Sync**

## 🐛 Issues Conhecidos

### Resolvidos
- ✅ Filtros de data corrigidos (formato YYYY-MM-DD)
- ✅ Build errors Kotlin/Gradle resolvidos
- ✅ Ícone personalizado implementado
- ✅ Flutter analyze limpo (0 problemas)

### Em Análise
- ⚠️ Dependências Android temporariamente removidas
- ⚠️ Sistema de backup simplificado

## 📋 Próximos Passos

### Desenvolvimento Imediato
1. **Reativar dependências** Android removidas
2. **Implementar login/cadastro** (telas + validação)
3. **API Service** para comunicação com backend
4. **Premium Service** para controle de acesso

### Integração Backend
1. **AuthService**: Login, cadastro, logout
2. **PremiumService**: Status, upgrade, downgrade  
3. **BackupService**: Upload/download automático
4. **SyncService**: Sincronização multi-device

## 🔄 Migração para Repositório Separado

Quando separado do monorepo:
- Mover todos os arquivos desta pasta para repo próprio
- Configurar CI/CD independente
- Manter comunicação com backend via API endpoints
- Deploy independente (APK vs API)

---

**Plataforma**: Android (Flutter)
**Status**: Em desenvolvimento ativo
**Deploy**: Codemagic CI/CD
**Próxima Release**: Premium integration