# 🚀 Guia Completo: Build APK no Codemagic

## ✅ Status do Projeto
- **Validação**: ✅ Passou em todos os testes
- **Dependencies**: ✅ Todas compatíveis (charts_flutter removido)
- **Configuração**: ✅ Android configurado (minSdk 21, targetSdk 34)
- **Workflow**: ✅ codemagic.yaml configurado

## 📋 Passo a Passo

### 1. **Preparar Repositório GitHub**
```bash
# Se ainda não fez, crie um repo no GitHub
git init
git add .
git commit -m "Projeto Motouber Flutter completo"
git remote add origin https://github.com/seu-usuario/motouber.git
git push -u origin main
```

### 2. **Configurar Codemagic**

#### A. Acessar e Conectar
1. Acesse: https://codemagic.io
2. Clique em "Sign up with GitHub"
3. Autorize o acesso aos repositórios
4. Selecione o repositório "motouber"

#### B. Configuração Automática
```yaml
# O arquivo codemagic.yaml já está configurado
# Codemagic detectará automaticamente
```

#### C. Configurações Personalizadas
```yaml
# Se quiser personalizar, edite codemagic.yaml:
workflows:
  android-workflow:
    max_build_duration: 60  # Ajuste se necessário
    instance_type: mac_mini_m1  # Ou linux_docker
```

### 3. **Primeiro Build**

#### A. Triggar Build
- **Opção 1**: Push código para GitHub (automático)
- **Opção 2**: Clique "Start new build" no Codemagic
- **Opção 3**: Configure webhook para builds automáticos

#### B. Monitorar Progresso
```bash
# Logs que você verá:
1. "Getting Flutter packages" (~2 min)
2. "Flutter analyze" (~1 min)
3. "Flutter test" (~1 min)
4. "Build APK" (~5-10 min)
```

#### C. Tempo Esperado
- **Primeiro build**: 10-15 minutos
- **Builds subsequentes**: 5-10 minutos

### 4. **Resultado**

#### A. Artifacts
- **APK**: `build/app/outputs/flutter-apk/app-release.apk`
- **Mapping**: `build/app/outputs/flutter-apk/mapping.txt`
- **Logs**: `flutter_drive.log`

#### B. Notificações
- **Email**: Configurado para notificar sucesso/falha
- **Download**: Link direto para APK

## 🔧 Configurações Avançadas

### 1. **Modificar Email** (codemagic.yaml)
```yaml
publishing:
  email:
    recipients:
      - seuemail@gmail.com  # Altere aqui
```

### 2. **Build Optimization**
```yaml
scripts:
  - name: Build APK Otimizado
    script: |
      flutter build apk --release --split-per-abi
      # Gera APKs menores por arquitetura
```

### 3. **Environment Variables**
```yaml
environment:
  vars:
    FLUTTER_VERSION: "3.24.0"  # Versão específica
    ANDROID_SDK_VERSION: "34"
```

## 📊 Monitoramento

### 1. **Status do Build**
- **Success**: ✅ APK pronto para download
- **Failed**: ❌ Verifique logs
- **Timeout**: ⏱️ Aumentar max_build_duration

### 2. **Logs Importantes**
```bash
# Em caso de erro, procure por:
- "FAILURE: Build failed"
- "Error: Could not find"
- "Exception in thread"
```

## 🚨 Troubleshooting

### 1. **Build Falha**
```bash
# Soluções comuns:
1. Verifique pubspec.yaml
2. Limpe cache: flutter clean
3. Atualize dependencies
4. Verifique logs detalhados
```

### 2. **Timeout**
```yaml
# Aumente timeout no codemagic.yaml:
max_build_duration: 90  # 90 minutos
```

### 3. **Dependências**
```bash
# Se der erro de dependência:
flutter pub get
flutter pub upgrade
```

## 📱 Testando o APK

### 1. **Download**
- Link estará no email de notificação
- Ou baixe direto do painel Codemagic

### 2. **Instalação**
```bash
# No Android:
1. Habilite "Fontes desconhecidas"
2. Instale o APK
3. Teste todas as funcionalidades
```

### 3. **Validação**
- ✅ Abertura do app
- ✅ Navegação entre telas
- ✅ Banco de dados funcionando
- ✅ Formulários salvando
- ✅ Gráficos carregando

## 🎯 Plano Gratuito

### Limites
- **500 minutos/mês**: ~40-50 builds
- **1 build simultâneo**: Suficiente
- **Repositórios ilimitados**: Perfeito

### Otimização
```bash
# Para economizar minutos:
1. Teste localmente antes
2. Use cache eficientemente
3. Builds incrementais
```

## 🔄 Automatização

### 1. **CI/CD Completo**
```yaml
# Webhook para builds automáticos
# Push → Build → Email → Install
```

### 2. **Branches**
```yaml
# Configure builds por branch:
triggering:
  events:
    - push
  branch_patterns:
    - pattern: 'main'
    - pattern: 'develop'
```

---

## 📋 Checklist Final

- [ ] Repositório GitHub configurado
- [ ] Codemagic conectado
- [ ] codemagic.yaml no root
- [ ] Email configurado
- [ ] Primeiro build executado
- [ ] APK testado no Android

**Resultado**: APK nativo de ~25MB, Android 5.0+, todas funcionalidades do Motouber funcionando!

---

**Próximo passo**: Faça push do código e conecte ao Codemagic! 🚀