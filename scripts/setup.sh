#!/bin/bash

# Script de setup para projetos VTEX
# Gerado pelo vtex-dev-tools

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para logging
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Função para verificar se um comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Função para verificar Docker
check_docker() {
    log_info "Verificando Docker..."
    
    if ! command_exists docker; then
        log_error "Docker não está instalado. Por favor, instale o Docker primeiro."
        exit 1
    fi
    
    if ! docker info >/dev/null 2>&1; then
        log_error "Docker não está rodando. Por favor, inicie o Docker."
        exit 1
    fi
    
    log_success "Docker está funcionando corretamente"
}

# Função para verificar Docker Compose
check_docker_compose() {
    log_info "Verificando Docker Compose..."
    
    if ! command_exists docker-compose; then
        log_error "Docker Compose não está instalado. Por favor, instale o Docker Compose."
        exit 1
    fi
    
    log_success "Docker Compose está disponível"
}

# Função para verificar Node.js
check_node() {
    log_info "Verificando Node.js..."
    
    if ! command_exists node; then
        log_warning "Node.js não está instalado localmente (será usado via Docker)"
        return
    fi
    
    NODE_VERSION=$(node --version | cut -d'v' -f2)
    MAJOR_VERSION=$(echo $NODE_VERSION | cut -d'.' -f1)
    
    if [ "$MAJOR_VERSION" -lt 14 ]; then
        log_warning "Node.js versão $NODE_VERSION detectada. Recomendamos versão 16+"
    else
        log_success "Node.js versão $NODE_VERSION está adequada"
    fi
}

# Função para verificar Yarn
check_yarn() {
    log_info "Verificando Yarn..."
    
    if ! command_exists yarn; then
        log_warning "Yarn não está instalado localmente (será usado via Docker)"
        return
    fi
    
    YARN_VERSION=$(yarn --version)
    log_success "Yarn versão $YARN_VERSION está disponível"
}

# Função para criar estrutura de diretórios
create_directories() {
    log_info "Criando estrutura de diretórios..."
    
    mkdir -p .vtex-dev
    mkdir -p docker
    mkdir -p scripts
    mkdir -p backups
    
    log_success "Estrutura de diretórios criada"
}

# Função para copiar arquivos de template
copy_templates() {
    log_info "Copiando templates..."
    
    # Verificar se os templates existem
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    TEMPLATES_DIR="$SCRIPT_DIR/../templates"
    
    if [ ! -d "$TEMPLATES_DIR" ]; then
        log_error "Diretório de templates não encontrado: $TEMPLATES_DIR"
        exit 1
    fi
    
    # Copiar Dockerfile
    if [ -f "$TEMPLATES_DIR/Dockerfile" ]; then
        cp "$TEMPLATES_DIR/Dockerfile" ./Dockerfile
        log_success "Dockerfile copiado"
    fi
    
    # Copiar docker-compose.yml
    if [ -f "$TEMPLATES_DIR/docker-compose.yml" ]; then
        cp "$TEMPLATES_DIR/docker-compose.yml" ./docker-compose.yml
        log_success "docker-compose.yml copiado"
    fi
    
    # Copiar .env.example
    if [ -f "$TEMPLATES_DIR/.env.example" ]; then
        cp "$TEMPLATES_DIR/.env.example" ./.env.example
        log_success ".env.example copiado"
    fi
    
    # Copiar .gitignore se não existir
    if [ ! -f "./.gitignore" ] && [ -f "$TEMPLATES_DIR/.gitignore" ]; then
        cp "$TEMPLATES_DIR/.gitignore" ./.gitignore
        log_success ".gitignore copiado"
    fi
    
    # Copiar Makefile
    if [ -f "$TEMPLATES_DIR/Makefile" ]; then
        cp "$TEMPLATES_DIR/Makefile" ./Makefile
        log_success "Makefile copiado"
    fi
}

# Função para configurar arquivo .env.local
setup_env_file() {
    log_info "Configurando arquivo .env.local..."
    
    if [ -f ".env.local" ]; then
        log_warning "Arquivo .env.local já existe. Fazendo backup..."
        cp .env.local .env.local.backup.$(date +%Y%m%d_%H%M%S)
    fi
    
    # Copiar do exemplo se não existir
    if [ ! -f ".env.local" ] && [ -f ".env.example" ]; then
        cp .env.example .env.local
        log_success "Arquivo .env.local criado a partir do exemplo"
        log_warning "Por favor, edite o arquivo .env.local com suas configurações"
    fi
}

# Função para construir imagem Docker
build_docker_image() {
    log_info "Construindo imagem Docker..."
    
    if docker-compose build; then
        log_success "Imagem Docker construída com sucesso"
    else
        log_error "Falha ao construir imagem Docker"
        exit 1
    fi
}

# Função para testar ambiente
test_environment() {
    log_info "Testando ambiente..."
    
    # Testar se o container pode ser iniciado
    if docker-compose run --rm vtex-dev node --version >/dev/null 2>&1; then
        log_success "Container Node.js está funcionando"
    else
        log_error "Falha ao testar container Node.js"
        exit 1
    fi
    
    # Testar VTEX CLI
    if docker-compose run --rm vtex-dev vtex --version >/dev/null 2>&1; then
        log_success "VTEX CLI está funcionando"
    else
        log_error "Falha ao testar VTEX CLI"
        exit 1
    fi
}

# Função para mostrar próximos passos
show_next_steps() {
    echo ""
    log_success "Setup concluído com sucesso!"
    echo ""
    echo -e "${BLUE}Próximos passos:${NC}"
    echo "1. Edite o arquivo .env.local com suas configurações VTEX"
    echo "2. Execute 'make dev' ou 'docker-compose up -d' para iniciar o ambiente"
    echo "3. Execute 'make login' ou 'docker-compose run --rm vtex-dev vtex login' para fazer login"
    echo "4. Execute 'make link' ou 'docker-compose run --rm vtex-dev vtex link' para linkar seu app"
    echo ""
    echo -e "${BLUE}Comandos úteis:${NC}"
    echo "- make help: Mostra todos os comandos disponíveis"
    echo "- make status: Mostra status do projeto"
    echo "- make logs: Mostra logs dos containers"
    echo "- make shell: Abre shell no container"
    echo ""
}

# Função principal
main() {
    echo -e "${BLUE}=== VTEX Development Environment Setup ===${NC}"
    echo ""
    
    # Verificações de pré-requisitos
    check_docker
    check_docker_compose
    check_node
    check_yarn
    
    echo ""
    
    # Setup do projeto
    create_directories
    copy_templates
    setup_env_file
    
    echo ""
    
    # Build e teste
    build_docker_image
    test_environment
    
    # Mostrar próximos passos
    show_next_steps
}

# Verificar se o script está sendo executado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi