#!/bin/bash

# Script de deploy para projetos VTEX
# Gerado pelo vtex-dev-tools

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variáveis padrão
ENVIRONMENT="staging"
SKIP_TESTS=false
SKIP_BUILD=false
FORCE_DEPLOY=false
VERBOSE=false

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

log_verbose() {
    if [ "$VERBOSE" = true ]; then
        echo -e "${BLUE}[VERBOSE]${NC} $1"
    fi
}

# Função para mostrar ajuda
show_help() {
    echo "Uso: $0 [OPÇÕES] [AMBIENTE]"
    echo ""
    echo "Ambientes disponíveis:"
    echo "  staging     Deploy para ambiente de staging (padrão)"
    echo "  production  Deploy para ambiente de produção"
    echo ""
    echo "Opções:"
    echo "  -h, --help          Mostra esta ajuda"
    echo "  -t, --skip-tests    Pula execução dos testes"
    echo "  -b, --skip-build    Pula execução do build"
    echo "  -f, --force         Força deploy sem confirmação"
    echo "  -v, --verbose       Modo verboso"
    echo ""
    echo "Exemplos:"
    echo "  $0 staging"
    echo "  $0 production --force"
    echo "  $0 --skip-tests --verbose"
}

# Função para verificar pré-requisitos
check_prerequisites() {
    log_info "Verificando pré-requisitos..."
    
    # Verificar se Docker está rodando
    if ! docker info >/dev/null 2>&1; then
        log_error "Docker não está rodando. Por favor, inicie o Docker."
        exit 1
    fi
    
    # Verificar se docker-compose.yml existe
    if [ ! -f "docker-compose.yml" ]; then
        log_error "Arquivo docker-compose.yml não encontrado. Execute o setup primeiro."
        exit 1
    fi
    
    # Verificar se .env.local existe
    if [ ! -f ".env.local" ]; then
        log_error "Arquivo .env.local não encontrado. Configure suas variáveis de ambiente."
        exit 1
    fi
    
    log_success "Pré-requisitos verificados"
}

# Função para carregar configurações
load_config() {
    log_info "Carregando configurações..."
    
    # Carregar variáveis do .env.local
    if [ -f ".env.local" ]; then
        export $(grep -v '^#' .env.local | xargs)
    fi
    
    # Verificar variáveis obrigatórias
    if [ -z "$VTEX_ACCOUNT" ]; then
        log_error "VTEX_ACCOUNT não está definido no .env.local"
        exit 1
    fi
    
    # Definir workspace baseado no ambiente
    case $ENVIRONMENT in
        "staging")
            WORKSPACE=${VTEX_STAGING_WORKSPACE:-"staging"}
            ;;
        "production")
            WORKSPACE=${VTEX_PRODUCTION_WORKSPACE:-"master"}
            ;;
        *)
            log_error "Ambiente inválido: $ENVIRONMENT"
            exit 1
            ;;
    esac
    
    log_success "Configurações carregadas - Account: $VTEX_ACCOUNT, Workspace: $WORKSPACE"
}

# Função para executar testes
run_tests() {
    if [ "$SKIP_TESTS" = true ]; then
        log_warning "Pulando execução dos testes"
        return
    fi
    
    log_info "Executando testes..."
    
    if docker-compose run --rm vtex-dev yarn test; then
        log_success "Testes executados com sucesso"
    else
        log_error "Falha nos testes"
        exit 1
    fi
}

# Função para executar build
run_build() {
    if [ "$SKIP_BUILD" = true ]; then
        log_warning "Pulando execução do build"
        return
    fi
    
    log_info "Executando build..."
    
    if docker-compose run --rm vtex-dev yarn build; then
        log_success "Build executado com sucesso"
    else
        log_error "Falha no build"
        exit 1
    fi
}

# Função para verificar login VTEX
check_vtex_login() {
    log_info "Verificando login VTEX..."
    
    # Verificar se está logado
    if ! docker-compose run --rm vtex-dev vtex whoami >/dev/null 2>&1; then
        log_warning "Não está logado no VTEX. Fazendo login..."
        
        if [ -n "$VTEX_TOKEN" ]; then
            # Login com token (para CI/CD)
            if docker-compose run --rm vtex-dev vtex login $VTEX_ACCOUNT --token $VTEX_TOKEN; then
                log_success "Login realizado com token"
            else
                log_error "Falha no login com token"
                exit 1
            fi
        else
            # Login interativo
            if docker-compose run --rm vtex-dev vtex login $VTEX_ACCOUNT; then
                log_success "Login realizado"
            else
                log_error "Falha no login"
                exit 1
            fi
        fi
    else
        log_success "Já está logado no VTEX"
    fi
}

# Função para mudar workspace
switch_workspace() {
    log_info "Mudando para workspace: $WORKSPACE"
    
    if docker-compose run --rm vtex-dev vtex use $WORKSPACE; then
        log_success "Workspace alterado para: $WORKSPACE"
    else
        log_error "Falha ao alterar workspace"
        exit 1
    fi
}

# Função para fazer deploy
perform_deploy() {
    log_info "Iniciando deploy para $ENVIRONMENT..."
    
    # Confirmar deploy para produção
    if [ "$ENVIRONMENT" = "production" ] && [ "$FORCE_DEPLOY" = false ]; then
        echo -e "${RED}ATENÇÃO: Você está fazendo deploy para PRODUÇÃO!${NC}"
        echo "Account: $VTEX_ACCOUNT"
        echo "Workspace: $WORKSPACE"
        echo ""
        read -p "Tem certeza que deseja continuar? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_warning "Deploy cancelado pelo usuário"
            exit 0
        fi
    fi
    
    # Publicar app
    log_info "Publicando app..."
    if docker-compose run --rm vtex-dev vtex publish --yes; then
        log_success "App publicado com sucesso"
    else
        log_error "Falha ao publicar app"
        exit 1
    fi
    
    # Fazer deploy
    log_info "Fazendo deploy..."
    if docker-compose run --rm vtex-dev vtex deploy --yes; then
        log_success "Deploy realizado com sucesso"
    else
        log_error "Falha no deploy"
        exit 1
    fi
}

# Função para verificar status pós-deploy
check_deploy_status() {
    log_info "Verificando status do deploy..."
    
    # Listar apps instalados
    log_verbose "Apps instalados:"
    docker-compose run --rm vtex-dev vtex list
    
    # Verificar se o app está funcionando
    APP_NAME=$(grep '"name"' manifest.json | cut -d'"' -f4 2>/dev/null || echo "unknown")
    if [ "$APP_NAME" != "unknown" ]; then
        log_info "Verificando app: $APP_NAME"
        docker-compose run --rm vtex-dev vtex list | grep "$APP_NAME" || log_warning "App não encontrado na lista"
    fi
    
    log_success "Verificação de status concluída"
}

# Função para criar backup
create_backup() {
    log_info "Criando backup..."
    
    BACKUP_DIR="backups"
    BACKUP_FILE="$BACKUP_DIR/deploy-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
    
    mkdir -p "$BACKUP_DIR"
    
    # Criar backup dos arquivos importantes
    tar -czf "$BACKUP_FILE" \
        manifest.json \
        .env.local \
        .vtex-dev/ \
        2>/dev/null || true
    
    if [ -f "$BACKUP_FILE" ]; then
        log_success "Backup criado: $BACKUP_FILE"
    else
        log_warning "Falha ao criar backup"
    fi
}

# Função para mostrar informações pós-deploy
show_deploy_info() {
    echo ""
    log_success "Deploy concluído com sucesso!"
    echo ""
    echo -e "${BLUE}Informações do deploy:${NC}"
    echo "Environment: $ENVIRONMENT"
    echo "Account: $VTEX_ACCOUNT"
    echo "Workspace: $WORKSPACE"
    echo "Timestamp: $(date)"
    echo ""
    echo -e "${BLUE}Próximos passos:${NC}"
    echo "1. Verifique se o app está funcionando corretamente"
    echo "2. Execute testes de aceitação se necessário"
    echo "3. Monitore logs para possíveis erros"
    echo ""
    echo -e "${BLUE}Comandos úteis:${NC}"
    echo "- make status: Verificar status do projeto"
    echo "- make logs: Ver logs dos containers"
    echo "- docker-compose run --rm vtex-dev vtex list: Listar apps instalados"
    echo ""
}

# Função principal
main() {
    # Parse dos argumentos
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -t|--skip-tests)
                SKIP_TESTS=true
                shift
                ;;
            -b|--skip-build)
                SKIP_BUILD=true
                shift
                ;;
            -f|--force)
                FORCE_DEPLOY=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            staging|production)
                ENVIRONMENT=$1
                shift
                ;;
            *)
                log_error "Opção desconhecida: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    echo -e "${BLUE}=== VTEX Deploy Script ===${NC}"
    echo "Environment: $ENVIRONMENT"
    echo ""
    
    # Executar pipeline de deploy
    check_prerequisites
    load_config
    create_backup
    run_tests
    run_build
    check_vtex_login
    switch_workspace
    perform_deploy
    check_deploy_status
    show_deploy_info
}

# Verificar se o script está sendo executado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi