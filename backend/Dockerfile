# Dockerfile para KM$ Backend - Dart/Shelf
FROM dart:stable

# Instalar dependências do sistema
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Configurar diretório de trabalho
WORKDIR /app

# Copiar arquivos de dependência
COPY pubspec.* ./
RUN dart pub get

# Copiar código fonte
COPY . .

# Expor porta (Fly.io usa PORT env var, padrão 8080)
EXPOSE 8080

# Executar servidor
CMD ["dart", "run", "bin/server.dart"]