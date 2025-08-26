#!/bin/bash

# Script de limpeza para projetos VTEX
# Gerado pelo vtex-dev-tools

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variáveis padrão
CLEAN_CONTAINERS=false
CLEAN_IMAGES=false
CLEAN_VOLUMES=false
CLEAN_NETWORKS=false
CLEAN_SYSTEM=false
CLEAN_NODE_MODULES=false
CLEAN_CACHE=false
FORCE_CLEAN=false
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
    echo "Uso: $0 [OPÇÕES]"
    echo ""
    echo "Opções de limpeza:"
    echo "  -c, --containers    Limpa containers parados"
    echo "  -i, --images        Limpa imagens não utilizadas"
    echo "  -v, --volumes       Limpa volumes não utilizados"
    echo "  -n, --networks      Limpa networks não utilizadas"
    echo "  -s, --system        Limpeza completa do sistema Docker"
    echo "  -m, --node-modules  Limpa node_modules"
    echo "  -a, --cache         Limpa cache (yarn, npm, etc.)"
    echo "  --all               Executa todas as limpezas"
    echo ""
    echo "Opções gerais:"
    echo "  -f, --force         Força limpeza sem confirmação"
    echo "  -v, --verbose       Modo verboso"
    echo "  -h, --help          Mostra esta ajuda"
    echo ""
    echo "Exemplos:"
    echo "  $0 --containers --images"
    echo "  $0 --all --force"
    echo "  $0 --node-modules --cache"
}

# Função para confirmar ação
confirm_action() {
    local message="$1"
    
    if [ "$FORCE_CLEAN" = true ]; then
        return 0
    fi
    
    echo -e "${YELLOW}$message${NC}"
    read -p "Tem certeza que deseja continuar? [y/N] " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_warning "Operação cancelada pelo usuário"
        return 1
    fi
    
    return 0
}

# Função para verificar Docker
check_docker() {
    if ! command -v docker >/dev/null 2>&1; then
        log_error "Docker não está instalado"
        exit 1
    fi
    
    if ! docker info >/dev/null 2>&1; then
        log_error "Docker não está rodando"
        exit 1
    fi
}

# Função para parar containers do projeto
stop_project_containers() {
    log_info "Parando containers do projeto..."
    
    if [ -f "docker-compose.yml" ]; then
        docker-compose down 2>/dev/null || true
        log_success "Containers do projeto parados"
    else
        log_warning "docker-compose.yml não encontrado"
    fi
}

# Função para limpar containers
clean_containers() {
    if [ "$CLEAN_CONTAINERS" = false ]; then
        return
    fi
    
    log_info "Limpando containers parados..."
    
    # Listar containers parados
    STOPPED_CONTAINERS=$(docker ps -aq --filter "status=exited")
    
    if [ -n "$STOPPED_CONTAINERS" ]; then
        if confirm_action "Isso removerá $(echo $STOPPED_CONTAINERS | wc -w) containers parados."; then
            docker rm $STOPPED_CONTAINERS
            log_success "Containers parados removidos"
        fi
    else
        log_info "Nenhum container parado encontrado"
    fi
}

# Função para limpar imagens
clean_images() {
    if [ "$CLEAN_IMAGES" = false ]; then
        return
    fi
    
    log_info "Limpando imagens não utilizadas..."
    
    # Listar imagens dangling
    DANGLING_IMAGES=$(docker images -qf "dangling=true")
    
    if [ -n "$DANGLING_IMAGES" ]; then
        if confirm_action "Isso removerá $(echo $DANGLING_IMAGES | wc -w) imagens dangling."; then
            docker rmi $DANGLING_IMAGES
            log_success "Imagens dangling removidas"
        fi
    else
        log_info "Nenhuma imagem dangling encontrada"
    fi
    
    # Limpar imagens não utilizadas
    if confirm_action "Remover todas as imagens não utilizadas?"; then
        docker image prune -f
        log_success "Imagens não utilizadas removidas"
    fi
}

# Função para limpar volumes
clean_volumes() {
    if [ "$CLEAN_VOLUMES" = false ]; then
        return
    fi
    
    log_info "Limpando volumes não utilizados..."
    
    # Listar volumes não utilizados
    UNUSED_VOLUMES=$(docker volume ls -qf "dangling=true")
    
    if [ -n "$UNUSED_VOLUMES" ]; then
        if confirm_action "Isso removerá $(echo $UNUSED_VOLUMES | wc -w) volumes não utilizados."; then
            docker volume rm $UNUSED_VOLUMES
            log_success "Volumes não utilizados removidos"
        fi
    else
        log_info "Nenhum volume não utilizado encontrado"
    fi
}

# Função para limpar networks
clean_networks() {
    if [ "$CLEAN_NETWORKS" = false ]; then
        return
    fi
    
    log_info "Limpando networks não utilizadas..."
    
    if confirm_action "Remover networks não utilizadas?"; then
        docker network prune -f
        log_success "Networks não utilizadas removidas"
    fi
}

# Função para limpeza completa do sistema
clean_system() {
    if [ "$CLEAN_SYSTEM" = false ]; then
        return
    fi
    
    log_info "Executando limpeza completa do sistema Docker..."
    
    if confirm_action "ATENÇÃO: Isso removerá TODOS os containers, imagens, volumes e networks não utilizados!"; then
        docker system prune -af --volumes
        log_success "Limpeza completa do sistema executada"
    fi
}

# Função para limpar node_modules
clean_node_modules() {
    if [ "$CLEAN_NODE_MODULES" = false ]; then
        return
    fi
    
    log_info "Limpando node_modules..."
    
    if [ -d "node_modules" ]; then
        if confirm_action "Isso removerá o diretório node_modules local."; then
            rm -rf node_modules
            log_success "node_modules local removido"
        fi
    else
        log_info "Diretório node_modules local não encontrado"
    fi
    
    # Limpar node_modules via Docker se o container existir
    if [ -f "docker-compose.yml" ]; then
        log_info "Limpando node_modules via Docker..."
        docker-compose run --rm vtex-dev rm -rf node_modules 2>/dev/null || true
        log_success "node_modules do container limpo"
    fi
}

# Função para limpar cache
clean_cache() {
    if [ "$CLEAN_CACHE" = false ]; then
        return
    fi
    
    log_info "Limpando cache..."
    
    # Limpar cache local se existir
    if command -v yarn >/dev/null 2>&1; then
        log_verbose "Limpando cache do Yarn local..."
        yarn cache clean 2>/dev/null || true
    fi
    
    if command -v npm >/dev/null 2>&1; then
        log_verbose "Limpando cache do NPM local..."
        npm cache clean --force 2>/dev/null || true
    fi
    
    # Limpar cache via Docker
    if [ -f "docker-compose.yml" ]; then
        log_verbose "Limpando cache via Docker..."
        docker-compose run --rm vtex-dev yarn cache clean 2>/dev/null || true
        docker-compose run --rm vtex-dev npm cache clean --force 2>/dev/null || true
    fi
    
    # Limpar diretórios de cache comuns
    local cache_dirs=(
        ".cache"
        ".parcel-cache"
        ".eslintcache"
        ".stylelintcache"
        "build"
        "dist"
        ".next"
    )
    
    for dir in "${cache_dirs[@]}"; do
        if [ -d "$dir" ]; then
            log_verbose "Removendo diretório de cache: $dir"
            rm -rf "$dir"
        fi
    done
    
    log_success "Cache limpo"
}

# Função para mostrar estatísticas de espaço
show_disk_usage() {
    log_info "Estatísticas de uso de disco:"
    
    echo -e "${BLUE}Docker:${NC}"
    docker system df 2>/dev/null || echo "Não foi possível obter estatísticas do Docker"
    
    echo ""
    echo -e "${BLUE}Diretório atual:${NC}"
    du -sh . 2>/dev/null || echo "Não foi possível obter tamanho do diretório"
    
    if [ -d "node_modules" ]; then
        echo "node_modules: $(du -sh node_modules 2>/dev/null | cut -f1)"
    fi
    
    echo ""
}

# Função para criar relatório de limpeza
create_cleanup_report() {
    local report_file="cleanup-report-$(date +%Y%m%d-%H%M%S).txt"
    
    log_info "Criando relatório de limpeza: $report_file"
    
    {
        echo "VTEX Cleanup Report"
        echo "=================="
        echo "Data: $(date)"
        echo "Diretório: $(pwd)"
        echo ""
        echo "Ações executadas:"
        [ "$CLEAN_CONTAINERS" = true ] && echo "- Containers limpos"
        [ "$CLEAN_IMAGES" = true ] && echo "- Imagens limpas"
        [ "$CLEAN_VOLUMES" = true ] && echo "- Volumes limpos"
        [ "$CLEAN_NETWORKS" = true ] && echo "- Networks limpas"
        [ "$CLEAN_SYSTEM" = true ] && echo "- Sistema Docker limpo"
        [ "$CLEAN_NODE_MODULES" = true ] && echo "- node_modules limpo"
        [ "$CLEAN_CACHE" = true ] && echo "- Cache limpo"
        echo ""
        echo "Estatísticas pós-limpeza:"
        docker system df 2>/dev/null || echo "Docker stats não disponíveis"
    } > "$report_file"
    
    log_success "Relatório criado: $report_file"
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
            -c|--containers)
                CLEAN_CONTAINERS=true
                shift
                ;;
            -i|--images)
                CLEAN_IMAGES=true
                shift
                ;;
            -v|--volumes)
                CLEAN_VOLUMES=true
                shift
                ;;
            -n|--networks)
                CLEAN_NETWORKS=true
                shift
                ;;
            -s|--system)
                CLEAN_SYSTEM=true
                shift
                ;;
            -m|--node-modules)
                CLEAN_NODE_MODULES=true
                shift
                ;;
            -a|--cache)
                CLEAN_CACHE=true
                shift
                ;;
            --all)
                CLEAN_CONTAINERS=true
                CLEAN_IMAGES=true
                CLEAN_VOLUMES=true
                CLEAN_NETWORKS=true
                CLEAN_NODE_MODULES=true
                CLEAN_CACHE=true
                shift
                ;;
            -f|--force)
                FORCE_CLEAN=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            *)
                log_error "Opção desconhecida: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Verificar se pelo menos uma opção foi selecionada
    if [ "$CLEAN_CONTAINERS" = false ] && 
       [ "$CLEAN_IMAGES" = false ] && 
       [ "$CLEAN_VOLUMES" = false ] && 
       [ "$CLEAN_NETWORKS" = false ] && 
       [ "$CLEAN_SYSTEM" = false ] && 
       [ "$CLEAN_NODE_MODULES" = false ] && 
       [ "$CLEAN_CACHE" = false ]; then
        log_error "Nenhuma opção de limpeza selecionada"
        show_help
        exit 1
    fi
    
    echo -e "${BLUE}=== VTEX Cleanup Script ===${NC}"
    echo ""
    
    # Mostrar estatísticas antes da limpeza
    show_disk_usage
    
    # Verificar Docker se necessário
    if [ "$CLEAN_CONTAINERS" = true ] || 
       [ "$CLEAN_IMAGES" = true ] || 
       [ "$CLEAN_VOLUMES" = true ] || 
       [ "$CLEAN_NETWORKS" = true ] || 
       [ "$CLEAN_SYSTEM" = true ]; then
        check_docker
    fi
    
    # Parar containers do projeto primeiro
    stop_project_containers
    
    # Executar limpezas
    clean_containers
    clean_images
    clean_volumes
    clean_networks
    clean_system
    clean_node_modules
    clean_cache
    
    echo ""
    log_success "Limpeza concluída!"
    
    # Mostrar estatísticas após limpeza
    show_disk_usage
    
    # Criar relatório
    create_cleanup_report
    
    echo ""
    log_info "Para reiniciar o ambiente de desenvolvimento, execute:"
    echo "make dev ou docker-compose up -d"
}

# Verificar se o script está sendo executado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi