# 🚀 Hungerz - Deploy de Produção com HTTPS

Este guia explica como fazer o deploy do Hungerz em produção com certificado SSL/HTTPS automático.

## ✅ Pré-requisitos

### Servidor
- VPS/servidor com Ubuntu 20.04+ ou Debian 11+
- Mínimo 2GB RAM, 2 CPUs
- 20GB+ de espaço em disco
- Acesso root (sudo)

### Domínio
- Domínio registrado (ex: `hungerz.com`)
- DNS apontando para o IP do servidor:
  - Registro A: `hungerz.com` → `SEU_IP_SERVIDOR`
  - Registro A: `www.hungerz.com` → `SEU_IP_SERVIDOR`

### Portas
- Porta 80 (HTTP) - aberta
- Porta 443 (HTTPS) - aberta
- Porta 22 (SSH) - aberta

## 🚀 Instalação Rápida

### 1. Preparar o servidor

```bash
# Atualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar git se necessário
sudo apt install git -y

# Clonar o projeto
git clone SEU_REPOSITORIO hungerz
cd hungerz
```

### 2. Executar setup de produção

```bash
# Dar permissão de execução
chmod +x setup-prod.sh

# Executar instalação (substitua pelo seu domínio)
sudo ./setup-prod.sh hungerz.com admin@hungerz.com

sudo ./setup-prod.sh betania.nuuque.com.br admin@betania.nuuque.com.br
```

O script irá:
- ✅ Instalar Docker e Docker Compose
- ✅ Configurar ambiente de produção
- ✅ Obter certificado SSL do Let's Encrypt
- ✅ Configurar nginx com HTTPS
- ✅ Subir todos os containers
- ✅ Executar migrations e seeders
- ✅ Configurar renovação automática do SSL

### 3. Aguardar conclusão

O processo pode levar de 10-15 minutos. Ao final você verá:

```
🎉 Ambiente Hungerz PRODUÇÃO configurado com sucesso!

📋 Serviços disponíveis:
   🍔 Aplicação Hungerz: https://hungerz.com
   🔒 Certificado SSL: ✅ Configurado
   🔄 Renovação automática: ✅ Configurada
```

## 🔧 Comandos Úteis

### Gerenciar containers
```bash
# Ver status dos containers
docker-compose -f docker-compose.prod.yml ps

# Ver logs em tempo real
docker-compose -f docker-compose.prod.yml logs -f

# Reiniciar um serviço
docker-compose -f docker-compose.prod.yml restart app

# Parar tudo
docker-compose -f docker-compose.prod.yml down

# Subir tudo novamente
docker-compose -f docker-compose.prod.yml up -d
```

### Laravel/PHP
```bash
# Executar comandos Artisan
docker-compose -f docker-compose.prod.yml exec app php artisan migrate
docker-compose -f docker-compose.prod.yml exec app php artisan cache:clear
docker-compose -f docker-compose.prod.yml exec app php artisan config:cache

# Composer
docker-compose -f docker-compose.prod.yml exec app composer install --no-dev
```

### SSL/Certificado
```bash
# Renovar certificado manualmente
docker-compose -f docker-compose.prod.yml exec certbot certbot renew

# Ver status do certificado
docker-compose -f docker-compose.prod.yml exec certbot certbot certificates

# Recarregar nginx após renovação
docker-compose -f docker-compose.prod.yml exec webserver nginx -s reload
```

## 🔐 Segurança

### 1. Configurar Firewall

```bash
# Instalar UFW
sudo apt install ufw -y

# Configurar regras básicas
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Permitir SSH, HTTP e HTTPS
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Ativar firewall
sudo ufw enable
```

### 2. Configurações importantes no .env

```env
# Produção
APP_ENV=production
APP_DEBUG=false
APP_URL=https://hungerz.com

# Senhas fortes
DB_ROOT_PASSWORD=senha_forte_root_mysql
DB_PASSWORD=senha_forte_laravel_mysql
REDIS_PASSWORD=senha_forte_redis

# SSL/HTTPS
SESSION_SECURE_COOKIE=true
SANCTUM_STATEFUL_DOMAINS=hungerz.com,www.hungerz.com
```

## 📊 Monitoramento

### Logs importantes
```bash
# Logs da aplicação
docker-compose -f docker-compose.prod.yml logs app

# Logs do nginx
docker-compose -f docker-compose.prod.yml logs webserver

# Logs do banco
docker-compose -f docker-compose.prod.yml logs db

# Logs do queue worker
docker-compose -f docker-compose.prod.yml logs queue
```

### Verificar status
```bash
# Status dos containers
docker-compose -f docker-compose.prod.yml ps

# Uso de recursos
docker stats

# Espaço em disco
df -h
```

## 🔄 Backup

### Banco de dados
```bash
# Criar backup
docker-compose -f docker-compose.prod.yml exec db mysqldump -u root -proot hungerz > backup-$(date +%Y%m%d).sql

# Restaurar backup
docker-compose -f docker-compose.prod.yml exec -i db mysql -u root -proot hungerz < backup-20240101.sql
```

### Arquivos
```bash
# Backup completo do projeto
tar -czf hungerz-backup-$(date +%Y%m%d).tar.gz /caminho/para/hungerz
```

## 🔧 Troubleshooting

### Problemas comuns

**1. Certificado SSL não foi gerado**
- Verificar se o domínio está apontando para o servidor
- Verificar se as portas 80 e 443 estão abertas
- Verificar logs: `docker-compose -f docker-compose.prod.yml logs certbot`

**2. Site não carrega**
- Verificar se nginx está rodando: `docker-compose -f docker-compose.prod.yml ps webserver`
- Verificar logs: `docker-compose -f docker-compose.prod.yml logs webserver`

**3. Erro 500**
- Verificar logs da aplicação: `docker-compose -f docker-compose.prod.yml logs app`
- Verificar permissões: `docker-compose -f docker-compose.prod.yml exec app ls -la storage/`

### Teste seu SSL
- https://www.ssllabs.com/ssltest/analyze.html?d=hungerz.com

## 📞 Suporte

Se precisar de ajuda:
1. Verifique os logs relevantes
2. Consulte a documentação do Laravel
3. Verifique issues no GitHub do projeto

---

**⚠️ Lembrete**: Sempre faça backup antes de atualizações importantes!