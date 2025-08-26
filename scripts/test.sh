#!/bin/bash

# Script de testes para projetos VTEX
# Gerado pelo vtex-dev-tools

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variáveis padrão
TEST_TYPE="all"
WATCH_MODE=false
COVERAGE=false
VERBOSE=false
CI_MODE=false
PARALLEL=false
UPDATE_SNAPSHOTS=false
BAIL=false
SILENT=false

# Função para logging
log_info() {
    if [ "$SILENT" = false ]; then
        echo -e "${BLUE}[INFO]${NC} $1"
    fi
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
    echo "Uso: $0 [OPÇÕES] [TIPO_TESTE]"
    echo ""
    echo "Tipos de teste:"
    echo "  unit           Executa apenas testes unitários"
    echo "  integration    Executa apenas testes de integração"
    echo "  e2e            Executa apenas testes end-to-end"
    echo "  lint           Executa apenas linting"
    echo "  type-check     Executa apenas verificação de tipos"
    echo "  all            Executa todos os testes (padrão)"
    echo ""
    echo "Opções:"
    echo "  -w, --watch           Modo watch (observa mudanças)"
    echo "  -c, --coverage        Gera relatório de cobertura"
    echo "  -v, --verbose         Modo verboso"
    echo "  --ci                  Modo CI (sem interação)"
    echo "  -p, --parallel        Executa testes em paralelo"
    echo "  -u, --update-snapshots Atualiza snapshots"
    echo "  -b, --bail            Para na primeira falha"
    echo "  -s, --silent          Modo silencioso"
    echo "  -h, --help            Mostra esta ajuda"
    echo ""
    echo "Exemplos:"
    echo "  $0 unit --coverage"
    echo "  $0 e2e --ci"
    echo "  $0 --watch"
    echo "  $0 lint"
}

# Função para verificar pré-requisitos
check_prerequisites() {
    log_verbose "Verificando pré-requisitos..."
    
    # Verificar Docker
    if ! command -v docker >/dev/null 2>&1; then
        log_error "Docker não está instalado"
        exit 1
    fi
    
    if ! docker info >/dev/null 2>&1; then
        log_error "Docker não está rodando"
        exit 1
    fi
    
    # Verificar docker-compose.yml
    if [ ! -f "docker-compose.yml" ]; then
        log_error "docker-compose.yml não encontrado"
        exit 1
    fi
    
    # Verificar se o projeto está inicializado
    if [ ! -f "package.json" ]; then
        log_error "package.json não encontrado. Execute 'vtex-dev init' primeiro."
        exit 1
    fi
    
    log_verbose "Pré-requisitos verificados"
}

# Função para carregar configurações
load_config() {
    log_verbose "Carregando configurações..."
    
    # Carregar .env.local se existir
    if [ -f ".env.local" ]; then
        set -a
        source .env.local
        set +a
        log_verbose "Configurações carregadas de .env.local"
    fi
    
    # Definir variáveis padrão se não estiverem definidas
    export NODE_ENV=${NODE_ENV:-test}
    export VTEX_ACCOUNT=${VTEX_ACCOUNT:-}
    export VTEX_WORKSPACE=${VTEX_WORKSPACE:-master}
}

# Função para executar testes unitários
run_unit_tests() {
    log_info "Executando testes unitários..."
    
    local jest_args=""
    
    if [ "$WATCH_MODE" = true ]; then
        jest_args="$jest_args --watch"
    fi
    
    if [ "$COVERAGE" = true ]; then
        jest_args="$jest_args --coverage"
    fi
    
    if [ "$CI_MODE" = true ]; then
        jest_args="$jest_args --ci --watchAll=false"
    fi
    
    if [ "$UPDATE_SNAPSHOTS" = true ]; then
        jest_args="$jest_args --updateSnapshot"
    fi
    
    if [ "$BAIL" = true ]; then
        jest_args="$jest_args --bail"
    fi
    
    if [ "$VERBOSE" = true ]; then
        jest_args="$jest_args --verbose"
    fi
    
    if [ "$SILENT" = true ]; then
        jest_args="$jest_args --silent"
    fi
    
    # Executar via Docker
    docker-compose run --rm vtex-test npm run test:unit $jest_args
    
    if [ $? -eq 0 ]; then
        log_success "Testes unitários passaram"
    else
        log_error "Testes unitários falharam"
        return 1
    fi
}

# Função para executar testes de integração
run_integration_tests() {
    log_info "Executando testes de integração..."
    
    local jest_args=""
    
    if [ "$COVERAGE" = true ]; then
        jest_args="$jest_args --coverage"
    fi
    
    if [ "$CI_MODE" = true ]; then
        jest_args="$jest_args --ci"
    fi
    
    if [ "$BAIL" = true ]; then
        jest_args="$jest_args --bail"
    fi
    
    if [ "$VERBOSE" = true ]; then
        jest_args="$jest_args --verbose"
    fi
    
    # Executar via Docker
    docker-compose run --rm vtex-test npm run test:integration $jest_args
    
    if [ $? -eq 0 ]; then
        log_success "Testes de integração passaram"
    else
        log_error "Testes de integração falharam"
        return 1
    fi
}

# Função para executar testes E2E
run_e2e_tests() {
    log_info "Executando testes end-to-end..."
    
    # Verificar se o ambiente de desenvolvimento está rodando
    if ! docker-compose ps | grep -q "vtex-dev.*Up"; then
        log_info "Iniciando ambiente de desenvolvimento para testes E2E..."
        docker-compose up -d vtex-dev
        
        # Aguardar o serviço estar pronto
        log_info "Aguardando serviço estar pronto..."
        sleep 30
        
        # Verificar se o serviço está respondendo
        local max_attempts=30
        local attempt=1
        
        while [ $attempt -le $max_attempts ]; do
            if curl -s http://localhost:3000 >/dev/null 2>&1; then
                log_success "Serviço está pronto"
                break
            fi
            
            log_verbose "Tentativa $attempt/$max_attempts - aguardando serviço..."
            sleep 2
            attempt=$((attempt + 1))
        done
        
        if [ $attempt -gt $max_attempts ]; then
            log_error "Serviço não ficou pronto a tempo"
            return 1
        fi
    fi
    
    local cypress_args=""
    
    if [ "$CI_MODE" = true ]; then
        cypress_args="$cypress_args --headless"
    fi
    
    if [ "$VERBOSE" = true ]; then
        cypress_args="$cypress_args --verbose"
    fi
    
    # Executar via Docker
    docker-compose run --rm vtex-test npm run test:e2e $cypress_args
    
    if [ $? -eq 0 ]; then
        log_success "Testes E2E passaram"
    else
        log_error "Testes E2E falharam"
        return 1
    fi
}

# Função para executar linting
run_lint() {
    log_info "Executando linting..."
    
    local eslint_args=""
    
    if [ "$CI_MODE" = true ]; then
        eslint_args="$eslint_args --format=junit --output-file=reports/eslint.xml"
    fi
    
    # ESLint
    docker-compose run --rm vtex-test npm run lint $eslint_args
    
    if [ $? -eq 0 ]; then
        log_success "ESLint passou"
    else
        log_error "ESLint falhou"
        return 1
    fi
    
    # Stylelint (se existir)
    if docker-compose run --rm vtex-test npm run stylelint >/dev/null 2>&1; then
        log_info "Executando Stylelint..."
        docker-compose run --rm vtex-test npm run stylelint
        
        if [ $? -eq 0 ]; then
            log_success "Stylelint passou"
        else
            log_error "Stylelint falhou"
            return 1
        fi
    fi
}

# Função para verificar tipos
run_type_check() {
    log_info "Executando verificação de tipos..."
    
    # TypeScript
    docker-compose run --rm vtex-test npm run type-check
    
    if [ $? -eq 0 ]; then
        log_success "Verificação de tipos passou"
    else
        log_error "Verificação de tipos falhou"
        return 1
    fi
}

# Função para gerar relatórios
generate_reports() {
    if [ "$CI_MODE" = true ]; then
        log_info "Gerando relatórios para CI..."
        
        # Criar diretório de relatórios
        mkdir -p reports
        
        # Copiar relatórios de cobertura se existirem
        if [ -d "coverage" ]; then
            cp -r coverage reports/
            log_success "Relatório de cobertura copiado"
        fi
        
        # Gerar relatório de resumo
        {
            echo "VTEX Test Report"
            echo "==============="
            echo "Data: $(date)"
            echo "Projeto: $(basename $(pwd))"
            echo "Tipo de teste: $TEST_TYPE"
            echo ""
            echo "Configurações:"
            echo "- Coverage: $COVERAGE"
            echo "- CI Mode: $CI_MODE"
            echo "- Parallel: $PARALLEL"
            echo "- Bail: $BAIL"
        } > reports/test-summary.txt
        
        log_success "Relatórios gerados em reports/"
    fi
}

# Função para executar todos os testes
run_all_tests() {
    log_info "Executando todos os testes..."
    
    local failed_tests=()
    
    # Linting
    if ! run_lint; then
        failed_tests+=("lint")
        if [ "$BAIL" = true ]; then
            return 1
        fi
    fi
    
    # Verificação de tipos
    if ! run_type_check; then
        failed_tests+=("type-check")
        if [ "$BAIL" = true ]; then
            return 1
        fi
    fi
    
    # Testes unitários
    if ! run_unit_tests; then
        failed_tests+=("unit")
        if [ "$BAIL" = true ]; then
            return 1
        fi
    fi
    
    # Testes de integração
    if ! run_integration_tests; then
        failed_tests+=("integration")
        if [ "$BAIL" = true ]; then
            return 1
        fi
    fi
    
    # Testes E2E (apenas se não estiver em modo watch)
    if [ "$WATCH_MODE" = false ]; then
        if ! run_e2e_tests; then
            failed_tests+=("e2e")
            if [ "$BAIL" = true ]; then
                return 1
            fi
        fi
    fi
    
    # Verificar resultados
    if [ ${#failed_tests[@]} -eq 0 ]; then
        log_success "Todos os testes passaram!"
        return 0
    else
        log_error "Testes falharam: ${failed_tests[*]}"
        return 1
    fi
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
            -w|--watch)
                WATCH_MODE=true
                shift
                ;;
            -c|--coverage)
                COVERAGE=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            --ci)
                CI_MODE=true
                shift
                ;;
            -p|--parallel)
                PARALLEL=true
                shift
                ;;
            -u|--update-snapshots)
                UPDATE_SNAPSHOTS=true
                shift
                ;;
            -b|--bail)
                BAIL=true
                shift
                ;;
            -s|--silent)
                SILENT=true
                shift
                ;;
            unit|integration|e2e|lint|type-check|all)
                TEST_TYPE="$1"
                shift
                ;;
            *)
                log_error "Opção desconhecida: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    echo -e "${BLUE}=== VTEX Test Runner ===${NC}"
    echo ""
    
    # Verificar pré-requisitos
    check_prerequisites
    
    # Carregar configurações
    load_config
    
    log_info "Executando testes do tipo: $TEST_TYPE"
    
    # Executar testes baseado no tipo
    case $TEST_TYPE in
        unit)
            run_unit_tests
            ;;
        integration)
            run_integration_tests
            ;;
        e2e)
            run_e2e_tests
            ;;
        lint)
            run_lint
            ;;
        type-check)
            run_type_check
            ;;
        all)
            run_all_tests
            ;;
        *)
            log_error "Tipo de teste inválido: $TEST_TYPE"
            exit 1
            ;;
    esac
    
    local exit_code=$?
    
    # Gerar relatórios
    generate_reports
    
    if [ $exit_code -eq 0 ]; then
        log_success "Testes concluídos com sucesso!"
    else
        log_error "Testes falharam!"
    fi
    
    exit $exit_code
}

# Verificar se o script está sendo executado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi