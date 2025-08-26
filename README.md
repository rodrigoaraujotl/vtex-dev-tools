# VTEX Dev Tools

🚀 Ferramenta CLI para automatizar o fluxo de desenvolvimento VTEX com Docker

## 📋 Índice

- [Sobre](#sobre)
- [Características](#características)
- [Instalação](#instalação)
- [Configuração](#configuração)
- [Comandos](#comandos)
- [Estrutura do Projeto](#estrutura-do-projeto)
- [Scripts de Automação](#scripts-de-automação)
- [Templates](#templates)
- [Desenvolvimento](#desenvolvimento)
- [Contribuição](#contribuição)
- [Licença](#licença)

## 🎯 Sobre

O **VTEX Dev Tools** é um pacote npm que automatiza e simplifica o fluxo de desenvolvimento para projetos VTEX IO, utilizando Docker para garantir consistência entre ambientes de desenvolvimento.

### Principais Benefícios

- ✅ **Ambiente Consistente**: Docker garante que todos os desenvolvedores trabalhem no mesmo ambiente
- ✅ **Setup Rápido**: Configuração inicial automatizada em poucos comandos
- ✅ **Fluxo Otimizado**: Comandos simplificados para tarefas comuns do VTEX
- ✅ **CI/CD Ready**: Templates prontos para integração contínua
- ✅ **Monitoramento**: Ferramentas de monitoramento e debugging integradas

## 🌟 Características

- **CLI Intuitiva**: Comandos simples e intuitivos
- **Docker First**: Tudo roda em containers Docker
- **Templates Prontos**: Dockerfile, docker-compose, CI/CD configurados
- **Scripts de Automação**: Deploy, testes, limpeza automatizados
- **Monitoramento**: Ferramentas de monitoramento em tempo real
- **Multiplataforma**: Funciona em Windows, macOS e Linux

## 📦 Instalação

### Pré-requisitos

- [Docker](https://docs.docker.com/get-docker/) >= 20.10
- [Docker Compose](https://docs.docker.com/compose/install/) >= 2.0
- [Node.js](https://nodejs.org/) >= 16.0
- [npm](https://www.npmjs.com/) ou [Yarn](https://yarnpkg.com/)

### Instalação Global

```bash
npm install -g @websense-dev-tools/vtex-dev-tools
```

Ou com Yarn:

```bash
yarn global add @websense-dev-tools/vtex-dev-tools
```

### Instalação Local (Desenvolvimento)

```bash
# Clone o repositório
git clone <repository-url>
cd vtex-dev-tools

# Instale as dependências
npm install

# Link globalmente para desenvolvimento
npm link
```

## ⚙️ Configuração

### Configuração Inicial

1. **Inicialize um novo projeto VTEX:**

```bash
vtex-dev init
```

2. **Configure suas credenciais VTEX:**

```bash
vtex-dev login
```

3. **Inicie o ambiente de desenvolvimento:**

```bash
vtex-dev dev
```

### Arquivo de Configuração

O comando `init` cria um arquivo `.env.local` com as configurações do projeto:

```env
# Configurações VTEX
VTEX_ACCOUNT=sua-conta
VTEX_WORKSPACE=master
VTEX_APP_ID=sua-app

# Configurações do Projeto
PROJECT_NAME=meu-projeto
DEV_PORT=3000
DEBUG_PORT=9229

# Configurações Docker
DOCKER_BUILDKIT=1
COMPOSE_DOCKER_CLI_BUILD=1
```

## 🛠️ Comandos

### Comandos Principais

#### `vtex-dev init`
Inicializa um novo projeto VTEX com toda a estrutura necessária.

```bash
vtex-dev init [opções]

Opções:
  --template <template>  Template a ser usado (padrão: default)
  --force               Sobrescreve arquivos existentes
  --skip-install        Pula a instalação de dependências
```

#### `vtex-dev dev`
Inicia o ambiente de desenvolvimento.

```bash
vtex-dev dev [opções]

Opções:
  --detached, -d        Executa em modo detached
  --rebuild             Reconstrói as imagens Docker
  --port <port>         Porta personalizada (padrão: 3000)
```

#### `vtex-dev build`
Constrói o projeto para produção.

```bash
vtex-dev build [ambiente] [opções]

Argumentos:
  ambiente              Ambiente de build (development, production)

Opções:
  --no-cache            Build sem cache
  --target <target>     Target específico do Dockerfile
```

#### `vtex-dev deploy`
Faz deploy do projeto.

```bash
vtex-dev deploy [ambiente] [opções]

Argumentos:
  ambiente              Ambiente de deploy (staging, production)

Opções:
  --skip-tests          Pula a execução de testes
  --skip-build          Pula o build
  --force               Força o deploy sem confirmação
```

### Comandos de Gerenciamento

#### `vtex-dev login`
Faz login na conta VTEX.

```bash
vtex-dev login [conta] [opções]

Argumentos:
  conta                 Conta VTEX (opcional)

Opções:
  --workspace <ws>      Workspace específico
  --token <token>       Token de autenticação
```

#### `vtex-dev link`
Linke o app no workspace atual.

```bash
vtex-dev link [opções]

Opções:
  --workspace <ws>      Workspace específico
  --watch               Modo watch para desenvolvimento
```

#### `vtex-dev unlink`
Deslinke o app do workspace.

```bash
vtex-dev unlink [app] [opções]

Argumentos:
  app                   App específico para deslinkar

Opções:
  --all                 Deslinkar todos os apps
```

### Comandos de Utilidade

#### `vtex-dev status`
Mostra o status do projeto e ambiente.

```bash
vtex-dev status [opções]

Opções:
  --detailed            Mostra informações detalhadas
  --json                Output em formato JSON
```

#### `vtex-dev clean`
Limpa containers, imagens e cache.

```bash
vtex-dev clean [opções]

Opções:
  --containers          Limpa apenas containers
  --images              Limpa apenas imagens
  --volumes             Limpa apenas volumes
  --all                 Limpeza completa
  --force               Força limpeza sem confirmação
```

## 📁 Estrutura do Projeto

Após executar `vtex-dev init`, a seguinte estrutura será criada:

```
meu-projeto-vtex/
├── .env.local              # Configurações do ambiente
├── .gitignore              # Arquivos ignorados pelo Git
├── Dockerfile              # Configuração do container
├── docker-compose.yml      # Orquestração dos serviços
├── Makefile               # Comandos make para automação
├── bitbucket-pipelines.yml # CI/CD para Bitbucket
├── .vtex-dev/             # Configurações do vtex-dev-tools
│   ├── config.json        # Configurações do projeto
│   └── backups/           # Backups automáticos
├── docker/                # Arquivos Docker customizados
├── scripts/               # Scripts de automação
│   ├── setup.sh          # Setup inicial
│   ├── deploy.sh         # Deploy automatizado
│   ├── cleanup.sh        # Limpeza do ambiente
│   ├── test.sh           # Execução de testes
│   └── monitor.sh        # Monitoramento
└── src/                   # Código fonte do projeto VTEX
    ├── manifest.json
    ├── store/
    ├── styles/
    └── react/
```

## 🤖 Scripts de Automação

### setup.sh
Script para configuração inicial do ambiente:

```bash
./scripts/setup.sh [opções]

Opções:
  --skip-docker         Pula verificação do Docker
  --skip-build          Pula build inicial
  --verbose             Modo verboso
```

### deploy.sh
Script para deploy automatizado:

```bash
./scripts/deploy.sh [ambiente] [opções]

Argumentos:
  ambiente              staging ou production

Opções:
  --skip-tests          Pula testes
  --skip-build          Pula build
  --force               Força deploy
  --verbose             Modo verboso
```

### cleanup.sh
Script para limpeza do ambiente:

```bash
./scripts/cleanup.sh [opções]

Opções:
  --containers          Limpa containers
  --images              Limpa imagens
  --volumes             Limpa volumes
  --all                 Limpeza completa
  --force               Sem confirmação
```

### test.sh
Script para execução de testes:

```bash
./scripts/test.sh [tipo] [opções]

Tipos:
  unit                  Testes unitários
  integration           Testes de integração
  e2e                   Testes end-to-end
  all                   Todos os testes

Opções:
  --watch               Modo watch
  --coverage            Cobertura de código
  --ci                  Modo CI
```

### monitor.sh
Script para monitoramento:

```bash
./scripts/monitor.sh [opções]

Opções:
  --continuous          Monitoramento contínuo
  --stats               Estatísticas detalhadas
  --logs                Mostra logs
  --interval <seconds>  Intervalo de atualização
```

## 📋 Templates

### Dockerfile
Template otimizado para desenvolvimento VTEX:

- Base Ubuntu com Node.js
- VTEX CLI pré-instalado
- Ferramentas de desenvolvimento
- Configuração de usuário não-root
- Cache otimizado para dependências

### docker-compose.yml
Orquestração completa com:

- Serviço de desenvolvimento (`vtex-dev`)
- Serviço de testes (`vtex-test`)
- Serviço de build (`vtex-build`)
- Volumes para cache e dados
- Rede isolada
- Variáveis de ambiente

### CI/CD (Bitbucket Pipelines)
Pipeline completa com:

- Testes automatizados
- Build para diferentes ambientes
- Deploy automatizado
- Verificações de segurança
- Cache otimizado

## 🔧 Desenvolvimento

### Configuração do Ambiente de Desenvolvimento

1. **Clone o repositório:**

```bash
git clone <repository-url>
cd vtex-dev-tools
```

2. **Instale as dependências:**

```bash
npm install
```

3. **Link para desenvolvimento:**

```bash
npm link
```

4. **Execute os testes:**

```bash
npm test
```

### Estrutura do Código

```
vtex-dev-tools/
├── bin/                   # Executáveis CLI
│   └── vtex-dev.js       # Ponto de entrada principal
├── lib/                   # Biblioteca principal
│   ├── commands/         # Implementação dos comandos
│   └── utils/            # Utilitários compartilhados
├── templates/            # Templates de arquivos
├── scripts/              # Scripts de automação
├── tests/                # Testes
└── docs/                 # Documentação
```

### Adicionando Novos Comandos

1. **Crie o arquivo do comando em `lib/commands/`:**

```javascript
// lib/commands/meu-comando.js
const { Command } = require('commander');

function meuComando(options) {
    // Implementação do comando
}

module.exports = {
    command: 'meu-comando',
    description: 'Descrição do comando',
    action: meuComando
};
```

2. **Registre o comando em `bin/vtex-dev.js`:**

```javascript
const meuComando = require('../lib/commands/meu-comando');
program
    .command(meuComando.command)
    .description(meuComando.description)
    .action(meuComando.action);
```

### Executando Testes

```bash
# Todos os testes
npm test

# Testes específicos
npm run test:unit
npm run test:integration

# Com cobertura
npm run test:coverage

# Modo watch
npm run test:watch
```

## 🤝 Contribuição

### Como Contribuir

1. **Fork o projeto**
2. **Crie uma branch para sua feature** (`git checkout -b feature/nova-feature`)
3. **Commit suas mudanças** (`git commit -am 'Adiciona nova feature'`)
4. **Push para a branch** (`git push origin feature/nova-feature`)
5. **Abra um Pull Request**

### Diretrizes

- Siga o padrão de código existente
- Adicione testes para novas funcionalidades
- Atualize a documentação quando necessário
- Use commits semânticos (conventional commits)

### Reportando Bugs

Ao reportar bugs, inclua:

- Versão do vtex-dev-tools
- Sistema operacional
- Versão do Docker
- Passos para reproduzir
- Logs de erro

## 📚 Recursos Adicionais

### Links Úteis

- [Documentação VTEX IO](https://developers.vtex.com/vtex-developer-docs/docs/vtex-io-documentation-what-is-vtex-io)
- [Docker Documentation](https://docs.docker.com/)
- [VTEX CLI](https://developers.vtex.com/vtex-developer-docs/docs/vtex-io-documentation-vtex-io-cli-installation-and-command-reference)

### Troubleshooting

#### Problemas Comuns

**Docker não está rodando:**
```bash
# Verificar status do Docker
docker info

# Iniciar Docker (macOS/Windows)
open -a Docker
```

**Porta já está em uso:**
```bash
# Verificar processos na porta
lsof -i :3000

# Usar porta diferente
vtex-dev dev --port 3001
```

**Problemas de permissão:**
```bash
# Adicionar usuário ao grupo docker (Linux)
sudo usermod -aG docker $USER

# Reiniciar sessão
newgrp docker
```

**Cache corrompido:**
```bash
# Limpar cache Docker
vtex-dev clean --all

# Rebuild completo
vtex-dev dev --rebuild
```

### FAQ

**Q: Posso usar com projetos VTEX existentes?**
A: Sim, execute `vtex-dev init` em um projeto existente. Os arquivos serão criados sem sobrescrever código existente.

**Q: Funciona no Windows?**
A: Sim, desde que tenha Docker Desktop instalado e WSL2 configurado.

**Q: Como atualizar o vtex-dev-tools?**
A: Execute `npm update -g @websense-dev-tools/vtex-dev-tools` ou `yarn global upgrade @websense-dev-tools/vtex-dev-tools`.

**Q: Posso customizar os templates?**
A: Sim, após a inicialização você pode modificar os arquivos gerados conforme necessário.

## 📄 Licença

Este projeto está licenciado sob a Licença MIT - veja o arquivo [LICENSE](LICENSE) para detalhes.

## 🏢 Sobre a J&J

Este projeto foi desenvolvido pela equipe de tecnologia da Johnson & Johnson para otimizar o fluxo de desenvolvimento de projetos VTEX.

---

**Desenvolvido com ❤️ pela equipe J&J Tech**