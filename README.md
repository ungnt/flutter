# 🚗 Motouber - Controle Financeiro para Motoristas

Aplicativo Flutter para gestão financeira e operacional de motoristas de aplicativo, com controle detalhado de trabalhos, gastos e manutenções.

## ✨ Funcionalidades

- 📊 **Dashboard** - Métricas do dia e mês
- 💼 **Registro de Trabalho** - Controle de ganhos diários
- 💰 **Controle de Gastos** - Categorização e histórico
- 🔧 **Manutenções** - Alertas e histórico de manutenções
- 📈 **Relatórios** - Gráficos e análises detalhadas
- ⚙️ **Configurações** - Backup e gerenciamento

## 🛠️ Tecnologias

- **Flutter 3.0+** - Framework multiplataforma
- **Dart** - Linguagem de programação
- **SQLite** - Banco de dados local
- **FL Chart** - Gráficos interativos
- **Material Design** - Interface moderna

## 🏗️ Estrutura do Projeto

```
motouber/
├── lib/
│   ├── main.dart              # Ponto de entrada
│   ├── models/                # Modelos de dados
│   ├── services/              # Serviços (Database)
│   ├── screens/               # Telas do aplicativo
│   └── theme/                 # Tema personalizado
├── android/                   # Configurações Android
├── codemagic.yaml            # CI/CD Codemagic
└── build_apk.sh              # Script de build VPS
```

## 🚀 Como usar

### Pré-requisitos
- Flutter SDK 3.0+
- Android SDK (para APK)
- Dart SDK

### Instalação
```bash
# Clone o repositório
git clone https://github.com/seu-usuario/motouber.git
cd motouber

# Instale as dependências
flutter pub get

# Execute o app
flutter run
```

### Build APK
```bash
# Build para produção
flutter build apk --release

# APK estará em: build/app/outputs/flutter-apk/app-release.apk
```

## 🎯 Deploy Automatizado

### Codemagic (Recomendado)
1. Conecte seu repositório ao [Codemagic](https://codemagic.io)
2. Use o arquivo `codemagic.yaml` já configurado
3. APK será gerado automaticamente

### VPS Build
```bash
# Configure o ambiente (Ubuntu 22.04)
chmod +x setup_vps.sh
./setup_vps.sh

# Build APK
chmod +x build_apk.sh
./build_apk.sh
```

## 📱 Funcionalidades Detalhadas

### Dashboard
- Ganhos do dia e mês
- Quilometragem percorrida
- Gastos por categoria
- Últimos registros

### Registro de Trabalho
- Formulário diário de trabalho
- Cálculo automático de ganhos/km
- Histórico com filtros
- Médias e totais

### Controle de Gastos
- Categorização automática
- Histórico detalhado
- Gráficos de distribuição
- Resumos por período

### Manutenções
- Registro de manutenções
- Alertas de próximas manutenções
- Histórico completo
- Cálculo de intervalos

### Relatórios
- Gráficos de performance
- Análise de rentabilidade
- Comparativos por período
- Métricas detalhadas

## 🔒 Segurança

- Todos os dados armazenados localmente
- Sem conexão com servidores externos
- Backup sob controle do usuário
- Apenas permissões essenciais

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

## 🤝 Contribuindo

1. Faça um fork do projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📞 Suporte

Se você encontrar algum problema ou tiver dúvidas:
- Abra uma [Issue](https://github.com/seu-usuario/motouber/issues)
- Descreva o problema detalhadamente
- Inclua logs se possível

---

**Desenvolvido com ❤️ para motoristas de aplicativo**