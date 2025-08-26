#!/bin/bash

# Script de monitoramento para projetos VTEX
# Gerado pelo vtex-dev-tools

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Variáveis padrão
MONITOR_INTERVAL=5
SHOW_LOGS=false
SHOW_STATS=false
CONTINUOUS=false
ALERT_THRESHOLD_CPU=80
ALERT_THRESHOLD_MEMORY=80
LOG_FILE=""
QUIET=false
WATCH_FILES=false

# Função para logging
log_info() {
    if [ "$QUIET" = false ]; then
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

log_alert() {
    echo -e "${RED}[ALERT]${NC} $1"
}

# Função para mostrar ajuda
show_help() {
    echo "Uso: $0 [OPÇÕES]"
    echo ""
    echo "Opções de monitoramento:"
    echo "  -i, --interval SECONDS    Intervalo de monitoramento (padrão: 5s)"
    echo "  -l, --logs               Mostra logs dos containers"
    echo "  -s, --stats              Mostra estatísticas detalhadas"
    echo "  -c, --continuous         Modo contínuo (não para)"
    echo "  -w, --watch-files        Monitora mudanças em arquivos"
    echo ""
    echo "Opções de alerta:"
    echo "  --cpu-threshold PERCENT   Limite de CPU para alertas (padrão: 80%)"
    echo "  --memory-threshold PERCENT Limite de memória para alertas (padrão: 80%)"
    echo ""
    echo "Opções de saída:"
    echo "  --log-file FILE          Salva logs em arquivo"
    echo "  -q, --quiet              Modo silencioso"
    echo "  -h, --help               Mostra esta ajuda"
    echo ""
    echo "Exemplos:"
    echo "  $0 --continuous --stats"
    echo "  $0 --logs --interval 10"
    echo "  $0 --watch-files --log-file monitor.log"
}

# Função para verificar pré-requisitos
check_prerequisites() {
    # Verificar Docker
    if ! command -v docker >/dev/null 2>&1; then
        log_error "Docker não está instalado"
        exit 1
    fi
    
    if ! docker info >/dev/null 2>&1; then
        log_error "Docker não está rodando"
        exit 1
    fi
    
    # Verificar docker-compose
    if ! command -v docker-compose >/dev/null 2>&1; then
        log_error "docker-compose não está instalado"
        exit 1
    fi
    
    # Verificar se o projeto está inicializado
    if [ ! -f "docker-compose.yml" ]; then
        log_error "docker-compose.yml não encontrado"
        exit 1
    fi
}

# Função para obter status dos containers
get_container_status() {
    local containers=$(docker-compose ps --services 2>/dev/null)
    
    echo -e "${CYAN}=== Status dos Containers ===${NC}"
    
    for service in $containers; do
        local status=$(docker-compose ps $service 2>/dev/null | tail -n +3 | awk '{print $4}')
        local container_id=$(docker-compose ps -q $service 2>/dev/null)
        
        if [ -n "$container_id" ]; then
            if [ "$status" = "Up" ]; then
                echo -e "${GREEN}✓${NC} $service: ${GREEN}Running${NC}"
            else
                echo -e "${RED}✗${NC} $service: ${RED}$status${NC}"
            fi
        else
            echo -e "${YELLOW}○${NC} $service: ${YELLOW}Not created${NC}"
        fi
    done
    
    echo ""
}

# Função para obter estatísticas dos containers
get_container_stats() {
    echo -e "${CYAN}=== Estatísticas dos Containers ===${NC}"
    
    local containers=$(docker-compose ps -q 2>/dev/null)
    
    if [ -z "$containers" ]; then
        echo "Nenhum container rodando"
        echo ""
        return
    fi
    
    # Header
    printf "%-15s %-10s %-10s %-15s %-15s\n" "CONTAINER" "CPU %" "MEM %" "MEM USAGE" "NET I/O"
    printf "%-15s %-10s %-10s %-15s %-15s\n" "---------" "-----" "-----" "---------" "------"
    
    for container_id in $containers; do
        local service=$(docker inspect --format='{{index .Config.Labels "com.docker.compose.service"}}' $container_id 2>/dev/null)
        local stats=$(docker stats --no-stream --format "table {{.CPUPerc}}\t{{.MemPerc}}\t{{.MemUsage}}\t{{.NetIO}}" $container_id 2>/dev/null | tail -n 1)
        
        if [ -n "$stats" ]; then
            local cpu=$(echo $stats | awk '{print $1}' | sed 's/%//')
            local mem=$(echo $stats | awk '{print $2}' | sed 's/%//')
            local mem_usage=$(echo $stats | awk '{print $3}')
            local net_io=$(echo $stats | awk '{print $4}')
            
            # Verificar alertas
            local cpu_alert=""
            local mem_alert=""
            
            if (( $(echo "$cpu > $ALERT_THRESHOLD_CPU" | bc -l) )); then
                cpu_alert="${RED}"
            fi
            
            if (( $(echo "$mem > $ALERT_THRESHOLD_MEMORY" | bc -l) )); then
                mem_alert="${RED}"
            fi
            
            printf "%-15s ${cpu_alert}%-10s${NC} ${mem_alert}%-10s${NC} %-15s %-15s\n" \
                "$service" "${cpu}%" "${mem}%" "$mem_usage" "$net_io"
            
            # Gerar alertas se necessário
            if [ -n "$cpu_alert" ]; then
                log_alert "$service: CPU usage high (${cpu}%)"
            fi
            
            if [ -n "$mem_alert" ]; then
                log_alert "$service: Memory usage high (${mem}%)"
            fi
        fi
    done
    
    echo ""
}

# Função para mostrar logs dos containers
show_container_logs() {
    echo -e "${CYAN}=== Logs dos Containers (últimas 10 linhas) ===${NC}"
    
    local services=$(docker-compose ps --services 2>/dev/null)
    
    for service in $services; do
        local container_id=$(docker-compose ps -q $service 2>/dev/null)
        
        if [ -n "$container_id" ]; then
            echo -e "${MAGENTA}--- $service ---${NC}"
            docker-compose logs --tail=10 $service 2>/dev/null || echo "Sem logs disponíveis"
            echo ""
        fi
    done
}

# Função para verificar saúde dos serviços
check_service_health() {
    echo -e "${CYAN}=== Verificação de Saúde dos Serviços ===${NC}"
    
    # Verificar se o serviço web está respondendo
    local web_port=$(grep -E "^\s*-\s*[0-9]+:3000" docker-compose.yml | sed 's/.*\([0-9]\+\):3000.*/\1/' | head -n 1)
    
    if [ -n "$web_port" ]; then
        if curl -s "http://localhost:$web_port" >/dev/null 2>&1; then
            echo -e "${GREEN}✓${NC} Web service: ${GREEN}Healthy${NC} (port $web_port)"
        else
            echo -e "${RED}✗${NC} Web service: ${RED}Unhealthy${NC} (port $web_port)"
        fi
    fi
    
    # Verificar VTEX CLI
    local vtex_container=$(docker-compose ps -q vtex-dev 2>/dev/null)
    if [ -n "$vtex_container" ]; then
        if docker exec $vtex_container vtex --version >/dev/null 2>&1; then
            echo -e "${GREEN}✓${NC} VTEX CLI: ${GREEN}Available${NC}"
        else
            echo -e "${RED}✗${NC} VTEX CLI: ${RED}Unavailable${NC}"
        fi
    fi
    
    # Verificar espaço em disco
    local disk_usage=$(df . | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ "$disk_usage" -gt 90 ]; then
        echo -e "${RED}✗${NC} Disk space: ${RED}Critical (${disk_usage}% used)${NC}"
        log_alert "Disk space critical: ${disk_usage}% used"
    elif [ "$disk_usage" -gt 80 ]; then
        echo -e "${YELLOW}⚠${NC} Disk space: ${YELLOW}Warning (${disk_usage}% used)${NC}"
    else
        echo -e "${GREEN}✓${NC} Disk space: ${GREEN}OK (${disk_usage}% used)${NC}"
    fi
    
    echo ""
}

# Função para monitorar mudanças em arquivos
watch_file_changes() {
    if [ "$WATCH_FILES" = false ]; then
        return
    fi
    
    echo -e "${CYAN}=== Monitoramento de Arquivos ===${NC}"
    
    # Verificar se fswatch está disponível
    if command -v fswatch >/dev/null 2>&1; then
        log_info "Monitorando mudanças em arquivos..."
        
        # Monitorar diretórios importantes
        local watch_dirs=("src" "styles" "store" "react" "node")
        local existing_dirs=()
        
        for dir in "${watch_dirs[@]}"; do
            if [ -d "$dir" ]; then
                existing_dirs+=("$dir")
            fi
        done
        
        if [ ${#existing_dirs[@]} -gt 0 ]; then
            fswatch -o "${existing_dirs[@]}" | while read num; do
                echo -e "${YELLOW}[$(date '+%H:%M:%S')]${NC} Detected $num file changes"
                
                # Log para arquivo se especificado
                if [ -n "$LOG_FILE" ]; then
                    echo "[$(date '+%Y-%m-%d %H:%M:%S')] File changes detected: $num" >> "$LOG_FILE"
                fi
            done &
        else
            log_warning "Nenhum diretório para monitorar encontrado"
        fi
    else
        log_warning "fswatch não está instalado. Instale com: brew install fswatch"
    fi
}

# Função para gerar relatório de sistema
generate_system_report() {
    echo -e "${CYAN}=== Relatório do Sistema ===${NC}"
    
    echo "Data: $(date)"
    echo "Projeto: $(basename $(pwd))"
    echo "Docker version: $(docker --version)"
    echo "Docker Compose version: $(docker-compose --version)"
    echo ""
    
    # Informações do sistema
    echo "Sistema operacional: $(uname -s)"
    echo "Arquitetura: $(uname -m)"
    echo "Uptime: $(uptime)"
    echo ""
    
    # Uso de recursos
    echo "Uso de CPU: $(top -l 1 | grep "CPU usage" | awk '{print $3}' | sed 's/%//' || echo 'N/A')"
    echo "Uso de memória: $(top -l 1 | grep "PhysMem" | awk '{print $2}' || echo 'N/A')"
    echo "Espaço em disco: $(df -h . | tail -1 | awk '{print $5}')"
    echo ""
}

# Função para salvar logs
save_to_log() {
    if [ -n "$LOG_FILE" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
    fi
}

# Função de monitoramento contínuo
continuous_monitor() {
    log_info "Iniciando monitoramento contínuo (intervalo: ${MONITOR_INTERVAL}s)"
    log_info "Pressione Ctrl+C para parar"
    
    # Configurar trap para limpeza
    trap 'echo ""; log_info "Parando monitoramento..."; exit 0' INT TERM
    
    # Iniciar monitoramento de arquivos se solicitado
    watch_file_changes
    
    while true; do
        clear
        
        echo -e "${BLUE}=== VTEX Development Monitor ===${NC}"
        echo "$(date)"
        echo ""
        
        get_container_status
        
        if [ "$SHOW_STATS" = true ]; then
            get_container_stats
        fi
        
        check_service_health
        
        if [ "$SHOW_LOGS" = true ]; then
            show_container_logs
        fi
        
        echo -e "${BLUE}Próxima atualização em ${MONITOR_INTERVAL}s...${NC}"
        
        save_to_log "Monitor check completed"
        
        sleep $MONITOR_INTERVAL
    done
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
            -i|--interval)
                MONITOR_INTERVAL="$2"
                shift 2
                ;;
            -l|--logs)
                SHOW_LOGS=true
                shift
                ;;
            -s|--stats)
                SHOW_STATS=true
                shift
                ;;
            -c|--continuous)
                CONTINUOUS=true
                shift
                ;;
            -w|--watch-files)
                WATCH_FILES=true
                shift
                ;;
            --cpu-threshold)
                ALERT_THRESHOLD_CPU="$2"
                shift 2
                ;;
            --memory-threshold)
                ALERT_THRESHOLD_MEMORY="$2"
                shift 2
                ;;
            --log-file)
                LOG_FILE="$2"
                shift 2
                ;;
            -q|--quiet)
                QUIET=true
                shift
                ;;
            *)
                log_error "Opção desconhecida: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Verificar pré-requisitos
    check_prerequisites
    
    # Criar arquivo de log se especificado
    if [ -n "$LOG_FILE" ]; then
        touch "$LOG_FILE"
        log_info "Logs serão salvos em: $LOG_FILE"
    fi
    
    if [ "$CONTINUOUS" = true ]; then
        continuous_monitor
    else
        # Execução única
        echo -e "${BLUE}=== VTEX Development Monitor ===${NC}"
        echo "$(date)"
        echo ""
        
        get_container_status
        
        if [ "$SHOW_STATS" = true ]; then
            get_container_stats
        fi
        
        check_service_health
        
        if [ "$SHOW_LOGS" = true ]; then
            show_container_logs
        fi
        
        generate_system_report
        
        save_to_log "Single monitor check completed"
    fi
}

# Verificar se o script está sendo executado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi