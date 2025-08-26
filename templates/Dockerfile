# Dockerfile para desenvolvimento VTEX
# Gerado pelo vtex-dev-tools

FROM node:20-alpine

# Instalar dependências do sistema
RUN apk add --no-cache \
    git \
    openssh-client \
    bash \
    curl \
    python3 \
    make \
    g++

# Definir diretório de trabalho
WORKDIR /app

# Instalar VTEX CLI globalmente
RUN yarn global add vtex

# Instalar dependências úteis para desenvolvimento
RUN yarn global add \
    npm-run-all \
    typescript \
    nodemon \
    concurrently

# Criar usuário não-root para segurança
RUN addgroup -g 1001 -S vtexdev && \
    adduser -S vtexdev -u 1001 -G vtexdev

# Configurar permissões
RUN chown -R vtexdev:vtexdev /app

# Mudar para usuário não-root
USER vtexdev

# Configurar variáveis de ambiente
ENV NODE_ENV=development
ENV VTEX_ENV=development
ENV PATH="/home/vtexdev/.yarn/bin:$PATH"

# Expor porta padrão do VTEX
EXPOSE 3000

# Comando padrão
CMD ["bash"]