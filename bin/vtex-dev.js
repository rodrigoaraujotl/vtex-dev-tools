#!/usr/bin/env node

const { Command } = require('commander');
const chalk = require('chalk');
const { initProject } = require('../lib/commands/init');
const { devEnvironment } = require('../lib/commands/dev');
const { buildProject } = require('../lib/commands/build');
const { deployProject } = require('../lib/commands/deploy');
const { cleanEnvironment } = require('../lib/commands/clean');
const { loginVtex } = require('../lib/commands/login');
const { linkProject } = require('../lib/commands/link');
const { unlinkProject } = require('../lib/commands/unlink');
const { statusCheck } = require('../lib/commands/status');

const program = new Command();

program
  .name('vtex-dev')
  .description('Ferramentas de desenvolvimento VTEX com Docker')
  .version('1.0.0');

// Comando init - Inicializar projeto
program
  .command('init')
  .description('Inicializar projeto VTEX com Docker')
  .option('-t, --template <type>', 'Tipo de template (basic, advanced)', 'basic')
  .option('-n, --name <name>', 'Nome do projeto')
  .action(async (options) => {
    try {
      console.log(chalk.blue('🚀 Inicializando projeto VTEX...'));
      await initProject(options);
      console.log(chalk.green('✅ Projeto inicializado com sucesso!'));
    } catch (error) {
      console.error(chalk.red('❌ Erro ao inicializar projeto:'), error.message);
      process.exit(1);
    }
  });

// Comando dev - Ambiente de desenvolvimento
program
  .command('dev')
  .description('Iniciar ambiente de desenvolvimento')
  .option('-d, --detached', 'Executar em background')
  .option('-p, --port <port>', 'Porta do servidor', '3000')
  .action(async (options) => {
    try {
      console.log(chalk.blue('🔧 Iniciando ambiente de desenvolvimento...'));
      await devEnvironment(options);
    } catch (error) {
      console.error(chalk.red('❌ Erro ao iniciar desenvolvimento:'), error.message);
      process.exit(1);
    }
  });

// Comando build - Build de produção
program
  .command('build')
  .description('Fazer build do projeto')
  .option('-e, --env <environment>', 'Ambiente (staging, production)', 'production')
  .option('--no-cache', 'Build sem cache')
  .action(async (options) => {
    try {
      console.log(chalk.blue('🏗️ Fazendo build do projeto...'));
      await buildProject(options);
      console.log(chalk.green('✅ Build concluído com sucesso!'));
    } catch (error) {
      console.error(chalk.red('❌ Erro no build:'), error.message);
      process.exit(1);
    }
  });

// Comando deploy - Deploy automatizado
program
  .command('deploy')
  .description('Deploy do projeto')
  .option('-e, --env <environment>', 'Ambiente (staging, production)', 'staging')
  .option('-w, --workspace <workspace>', 'Workspace VTEX')
  .option('--force', 'Forçar deploy')
  .action(async (options) => {
    try {
      console.log(chalk.blue('🚀 Iniciando deploy...'));
      await deployProject(options);
      console.log(chalk.green('✅ Deploy concluído com sucesso!'));
    } catch (error) {
      console.error(chalk.red('❌ Erro no deploy:'), error.message);
      process.exit(1);
    }
  });

// Comando clean - Limpeza de containers
program
  .command('clean')
  .description('Limpar containers e volumes Docker')
  .option('-a, --all', 'Limpar tudo (containers, volumes, imagens)')
  .option('-f, --force', 'Forçar limpeza')
  .action(async (options) => {
    try {
      console.log(chalk.yellow('🧹 Limpando ambiente Docker...'));
      await cleanEnvironment(options);
      console.log(chalk.green('✅ Limpeza concluída!'));
    } catch (error) {
      console.error(chalk.red('❌ Erro na limpeza:'), error.message);
      process.exit(1);
    }
  });

// Comando login - Login VTEX
program
  .command('login')
  .description('Fazer login no VTEX')
  .option('-a, --account <account>', 'Account VTEX')
  .action(async (options) => {
    try {
      console.log(chalk.blue('🔐 Fazendo login no VTEX...'));
      await loginVtex(options);
      console.log(chalk.green('✅ Login realizado com sucesso!'));
    } catch (error) {
      console.error(chalk.red('❌ Erro no login:'), error.message);
      process.exit(1);
    }
  });

// Comando link - Link do projeto
program
  .command('link')
  .description('Fazer link do projeto VTEX')
  .option('-w, --workspace <workspace>', 'Workspace VTEX')
  .action(async (options) => {
    try {
      console.log(chalk.blue('🔗 Fazendo link do projeto...'));
      await linkProject(options);
      console.log(chalk.green('✅ Link realizado com sucesso!'));
    } catch (error) {
      console.error(chalk.red('❌ Erro no link:'), error.message);
      process.exit(1);
    }
  });

// Comando unlink - Unlink do projeto
program
  .command('unlink')
  .description('Fazer unlink do projeto VTEX')
  .option('-a, --all', 'Unlink de todos os apps')
  .action(async (options) => {
    try {
      console.log(chalk.yellow('🔓 Fazendo unlink do projeto...'));
      await unlinkProject(options);
      console.log(chalk.green('✅ Unlink realizado com sucesso!'));
    } catch (error) {
      console.error(chalk.red('❌ Erro no unlink:'), error.message);
      process.exit(1);
    }
  });

// Comando status - Verificar status
program
  .command('status')
  .description('Verificar status do ambiente')
  .action(async () => {
    try {
      await statusCheck();
    } catch (error) {
      console.error(chalk.red('❌ Erro ao verificar status:'), error.message);
      process.exit(1);
    }
  });

// Parse dos argumentos
program.parse(process.argv);

// Se nenhum comando foi fornecido, mostrar ajuda
if (!process.argv.slice(2).length) {
  program.outputHelp();
}