# Makefile para desenvolvimento VTEX
# Gerado pelo vtex-dev-tools

# Variáveis
PROJECT_NAME ?= vtex-app
DOCKER_COMPOSE = docker-compose
DOCKER = docker

# Cores para output
RED = \033[0;31m
GREEN = \033[0;32m
YELLOW = \033[1;33m
BLUE = \033[0;34m
NC = \033[0m # No Color

.PHONY: help install dev build test clean login link unlink status logs shell

# Target padrão
help: ## Mostra esta ajuda
	@echo "$(BLUE)Comandos disponíveis para $(PROJECT_NAME):$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "$(GREEN)%-15s$(NC) %s\n", $$1, $$2}'
	@echo ""

install: ## Instala dependências do projeto
	@echo "$(YELLOW)Instalando dependências...$(NC)"
	$(DOCKER_COMPOSE) run --rm vtex-dev yarn install
	@echo "$(GREEN)Dependências instaladas com sucesso!$(NC)"

dev: ## Inicia ambiente de desenvolvimento
	@echo "$(YELLOW)Iniciando ambiente de desenvolvimento...$(NC)"
	$(DOCKER_COMPOSE) up -d vtex-dev
	@echo "$(GREEN)Ambiente iniciado! Acesse: http://localhost:3000$(NC)"

dev-logs: ## Mostra logs do ambiente de desenvolvimento
	$(DOCKER_COMPOSE) logs -f vtex-dev

stop: ## Para o ambiente de desenvolvimento
	@echo "$(YELLOW)Parando ambiente de desenvolvimento...$(NC)"
	$(DOCKER_COMPOSE) stop
	@echo "$(GREEN)Ambiente parado!$(NC)"

restart: ## Reinicia o ambiente de desenvolvimento
	@echo "$(YELLOW)Reiniciando ambiente...$(NC)"
	$(DOCKER_COMPOSE) restart vtex-dev
	@echo "$(GREEN)Ambiente reiniciado!$(NC)"

build: ## Executa build do projeto
	@echo "$(YELLOW)Executando build...$(NC)"
	$(DOCKER_COMPOSE) run --rm vtex-dev yarn build
	@echo "$(GREEN)Build concluído!$(NC)"

build-prod: ## Executa build de produção
	@echo "$(YELLOW)Executando build de produção...$(NC)"
	$(DOCKER_COMPOSE) --profile build up vtex-build
	@echo "$(GREEN)Build de produção concluído!$(NC)"

test: ## Executa testes
	@echo "$(YELLOW)Executando testes...$(NC)"
	$(DOCKER_COMPOSE) --profile testing run --rm vtex-test
	@echo "$(GREEN)Testes concluídos!$(NC)"

test-watch: ## Executa testes em modo watch
	@echo "$(YELLOW)Executando testes em modo watch...$(NC)"
	$(DOCKER_COMPOSE) run --rm vtex-dev yarn test --watch

lint: ## Executa linting do código
	@echo "$(YELLOW)Executando linting...$(NC)"
	$(DOCKER_COMPOSE) run --rm vtex-dev yarn lint
	@echo "$(GREEN)Linting concluído!$(NC)"

format: ## Formata o código
	@echo "$(YELLOW)Formatando código...$(NC)"
	$(DOCKER_COMPOSE) run --rm vtex-dev yarn format
	@echo "$(GREEN)Código formatado!$(NC)"

login: ## Faz login no VTEX
	@echo "$(YELLOW)Fazendo login no VTEX...$(NC)"
	$(DOCKER_COMPOSE) run --rm vtex-dev vtex login
	@echo "$(GREEN)Login realizado!$(NC)"

logout: ## Faz logout do VTEX
	@echo "$(YELLOW)Fazendo logout do VTEX...$(NC)"
	$(DOCKER_COMPOSE) run --rm vtex-dev vtex logout
	@echo "$(GREEN)Logout realizado!$(NC)"

link: ## Faz link do app VTEX
	@echo "$(YELLOW)Fazendo link do app...$(NC)"
	$(DOCKER_COMPOSE) run --rm vtex-dev vtex link
	@echo "$(GREEN)App linkado!$(NC)"

unlink: ## Remove link do app VTEX
	@echo "$(YELLOW)Removendo link do app...$(NC)"
	$(DOCKER_COMPOSE) run --rm vtex-dev vtex unlink
	@echo "$(GREEN)Link removido!$(NC)"

publish: ## Publica o app VTEX
	@echo "$(YELLOW)Publicando app...$(NC)"
	$(DOCKER_COMPOSE) run --rm vtex-dev vtex publish
	@echo "$(GREEN)App publicado!$(NC)"

deploy: ## Faz deploy do app VTEX
	@echo "$(YELLOW)Fazendo deploy...$(NC)"
	$(DOCKER_COMPOSE) run --rm vtex-dev vtex deploy
	@echo "$(GREEN)Deploy realizado!$(NC)"

status: ## Mostra status do projeto
	@echo "$(BLUE)Status do projeto $(PROJECT_NAME):$(NC)"
	@echo ""
	@echo "$(YELLOW)Containers:$(NC)"
	@$(DOCKER_COMPOSE) ps
	@echo ""
	@echo "$(YELLOW)VTEX Status:$(NC)"
	@$(DOCKER_COMPOSE) run --rm vtex-dev vtex whoami || echo "$(RED)Não logado no VTEX$(NC)"

shell: ## Abre shell no container
	@echo "$(YELLOW)Abrindo shell no container...$(NC)"
	$(DOCKER_COMPOSE) exec vtex-dev bash

shell-run: ## Executa shell em novo container
	@echo "$(YELLOW)Executando shell em novo container...$(NC)"
	$(DOCKER_COMPOSE) run --rm vtex-dev bash

logs: ## Mostra logs dos containers
	$(DOCKER_COMPOSE) logs -f

clean: ## Limpa containers e volumes
	@echo "$(YELLOW)Limpando containers e volumes...$(NC)"
	$(DOCKER_COMPOSE) down -v
	$(DOCKER) system prune -f
	@echo "$(GREEN)Limpeza concluída!$(NC)"

clean-all: ## Limpa tudo (containers, volumes, imagens)
	@echo "$(RED)ATENÇÃO: Isso removerá todos os containers, volumes e imagens!$(NC)"
	@read -p "Tem certeza? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		$(DOCKER_COMPOSE) down -v --rmi all; \
		$(DOCKER) system prune -af; \
		echo "$(GREEN)Limpeza completa concluída!$(NC)"; \
	else \
		echo "$(YELLOW)Operação cancelada.$(NC)"; \
	fi

rebuild: ## Reconstrói as imagens Docker
	@echo "$(YELLOW)Reconstruindo imagens...$(NC)"
	$(DOCKER_COMPOSE) build --no-cache
	@echo "$(GREEN)Imagens reconstruídas!$(NC)"

update: ## Atualiza dependências
	@echo "$(YELLOW)Atualizando dependências...$(NC)"
	$(DOCKER_COMPOSE) run --rm vtex-dev yarn upgrade
	@echo "$(GREEN)Dependências atualizadas!$(NC)"

backup: ## Cria backup das configurações
	@echo "$(YELLOW)Criando backup...$(NC)"
	@mkdir -p backups
	@tar -czf backups/vtex-config-$(shell date +%Y%m%d-%H%M%S).tar.gz .vtex .env.local || true
	@echo "$(GREEN)Backup criado em backups/$(NC)"

info: ## Mostra informações do sistema
	@echo "$(BLUE)Informações do sistema:$(NC)"
	@echo "Docker: $$(docker --version)"
	@echo "Docker Compose: $$(docker-compose --version)"
	@echo "Projeto: $(PROJECT_NAME)"
	@echo "Diretório: $$(pwd)"
	@echo ""