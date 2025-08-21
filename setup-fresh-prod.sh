#!/bin/bash

echo "🚀 SETUP FRESCO - Hungerz Produção com HTTPS..."

# Verificar se está rodando como root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Execute como root: sudo ./setup-fresh-prod.sh DOMINIO [EMAIL]"
    exit 1
fi

# Verificar parâmetros
if [ -z "$1" ]; then
    echo "❌ Uso: sudo ./setup-fresh-prod.sh SEU_DOMINIO.com [EMAIL]"
    echo "Exemplo: sudo ./setup-fresh-prod.sh betania.nuuque.com.br admin@betania.nuuque.com.br"
    exit 1
fi

DOMAIN=$1
EMAIL=${2:-"admin@$DOMAIN"}

echo "📋 Configuração:"
echo "   🌐 Domínio: $DOMAIN"
echo "   📧 Email: $EMAIL"
echo ""

# Verificar se existe projeto Laravel
if [ ! -f "artisan" ]; then
    echo "❌ Projeto Hungerz não encontrado!"
    exit 1
fi

echo "🧹 LIMPEZA COMPLETA..."
# Parar e remover tudo
docker-compose -f docker-compose.prod.yml down --remove-orphans --volumes 2>/dev/null || true
docker system prune -af
docker volume prune -f

# Remover arquivos problemáticos
rm -f composer.lock
rm -rf vendor/
rm -rf storage/logs/*
rm -rf bootstrap/cache/*

echo "🔄 Atualizando sistema..."
apt-get update && apt-get upgrade -y

# Instalar Docker se necessário
if ! command -v docker &> /dev/null; then
    echo "🐳 Instalando Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
fi

if ! command -v docker-compose &> /dev/null; then
    echo "🐳 Instalando Docker Compose..."
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
fi

echo "📁 Criando estrutura completa de diretórios..."
mkdir -p docker/{nginx-prod,certbot/{conf,www}}
mkdir -p storage/{app/{public,temp,uploads},framework/{cache,sessions,testing,views},logs}
mkdir -p bootstrap/cache
mkdir -p public/storage

echo "🔧 Configurando .env de produção..."
# Backup do .env atual
[ -f .env ] && cp .env .env.backup.$(date +%Y%m%d_%H%M%S)

# Criar .env baseado no exemplo
cp .env.example .env

# Configurar para produção
cat > .env << EOF
APP_NAME=Hungerz
APP_ENV=production
APP_KEY=
APP_URL=https://$DOMAIN
APP_DEBUG=false
APP_LOG_LEVEL=error
APP_LOCALE=en
APP_FALLBACK_LOCALE=en
APP_TIMEZONE=UTC

# DATABASE - PRODUÇÃO
DB_CONNECTION=mysql
DB_HOST=db
DB_PORT=3306
DB_DATABASE=hungerz
DB_USERNAME=laravel
DB_PASSWORD=laravel_prod_$(openssl rand -hex 8)
DB_ROOT_PASSWORD=root_prod_$(openssl rand -hex 12)

# REDIS
REDIS_HOST=redis
REDIS_PASSWORD=redis_prod_$(openssl rand -hex 8)
REDIS_PORT=6379

# CACHE
CACHE_DRIVER=file
SESSION_DRIVER=file
SESSION_LIFETIME=120
SESSION_SECURE_COOKIE=true
QUEUE_CONNECTION=database

# MAIL - Configure seu provedor
MAIL_DRIVER=smtp
MAIL_HOST=
MAIL_PORT=587
MAIL_USERNAME=
MAIL_PASSWORD=
MAIL_ENCRYPTION=tls
MAIL_FROM_ADDRESS=noreply@$DOMAIN
MAIL_FROM_NAME=Hungerz

# PAGAMENTOS - Configure suas chaves
STRIPE_KEY=
STRIPE_SECRET=
PAYSTACK_SECURE_KEY=
MOLLIE_API_KEY=

# SOCIAL
GOOGLE_CLIENT_ID=
FACEBOOK_APP_ID=
FACEBOOK_APP_SECRET=

# SECURITY
SANCTUM_STATEFUL_DOMAINS=$DOMAIN,www.$DOMAIN
BCRYPT_ROUNDS=12

# TELESCOPE - DESABILITADO
TELESCOPE_ENABLED=false

# OUTROS
DEMO_ENABLED=false
MOBILE_NUMBER_LENGTH=10
EOF

echo "🔒 Configurando permissões do sistema..."
chown -R 1000:1000 .
chmod -R 755 .
chmod -R 775 storage bootstrap/cache public/storage

echo "🔨 Atualizando Dockerfile para produção..."
# Backup do Dockerfile
cp docker/php/Dockerfile docker/php/Dockerfile.backup

# Dockerfile otimizado
cat > docker/php/Dockerfile << 'DOCKERFILE_EOF'
FROM php:8.2-fpm

# Argumentos
ARG user=laravel
ARG uid=1000

# Instalar dependências do sistema
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    libicu-dev \
    zip \
    unzip \
    nano \
    cron \
    supervisor

# Limpar cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Instalar extensões PHP necessárias
RUN docker-php-ext-configure intl
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd zip intl

# Instalar Redis PHP extension
RUN pecl install redis && docker-php-ext-enable redis

# Instalar Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Criar usuário do sistema
RUN useradd -G www-data,root -u ${uid} -d /home/${user} ${user}
RUN mkdir -p /home/${user}/.composer && \
    chown -R ${user}:${user} /home/${user}

# Configurar diretório de trabalho
WORKDIR /var/www

# Copiar configuração PHP
COPY docker/php/local.ini /usr/local/etc/php/conf.d/local.ini

# Configurar git safe directory
RUN git config --global --add safe.directory /var/www

# Trocar para o usuário
USER ${user}
DOCKERFILE_EOF

echo "🐳 Atualizando docker-compose.prod.yml..."
cat > docker-compose.prod.yml << 'COMPOSE_EOF'
services:
  # Aplicação PHP-FPM
  app:
    build:
      context: .
      dockerfile: docker/php/Dockerfile
      args:
        user: laravel
        uid: 1000
    container_name: hungerz_app_prod
    restart: unless-stopped
    working_dir: /var/www
    volumes:
      - ./:/var/www
      - ./docker/php/local.ini:/usr/local/etc/php/conf.d/local.ini
    networks:
      - hungerz_prod
    depends_on:
      db:
        condition: service_healthy
    environment:
      - APP_ENV=production
      - APP_DEBUG=false

  # Nginx Web Server
  webserver:
    image: nginx:alpine
    container_name: hungerz_webserver_prod
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./:/var/www
      - ./docker/nginx-prod:/etc/nginx/conf.d
      - ./docker/certbot/conf:/etc/letsencrypt
      - ./docker/certbot/www:/var/www/certbot
    networks:
      - hungerz_prod
    depends_on:
      - app
    command: "/bin/sh -c 'while :; do sleep 6h & wait $${!}; nginx -s reload; done & nginx -g \"daemon off;\"'"

  # Certbot para SSL
  certbot:
    image: certbot/certbot
    container_name: hungerz_certbot
    restart: unless-stopped
    volumes:
      - ./docker/certbot/conf:/etc/letsencrypt
      - ./docker/certbot/www:/var/www/certbot
    networks:
      - hungerz_prod
    entrypoint: "/bin/sh -c 'trap exit TERM; while :; do certbot renew; sleep 12h & wait $${!}; done;'"

  # MySQL Database
  db:
    image: mysql:8.0
    container_name: hungerz_db_prod
    restart: unless-stopped
    environment:
      MYSQL_DATABASE: hungerz
      MYSQL_ROOT_PASSWORD: ${DB_ROOT_PASSWORD}
      MYSQL_PASSWORD: ${DB_PASSWORD}
      MYSQL_USER: ${DB_USERNAME}
      SERVICE_TAGS: prod
      SERVICE_NAME: mysql
    volumes:
      - dbdata_prod:/var/lib/mysql
      - ./docker/mysql/my.cnf:/etc/mysql/my.cnf
    networks:
      - hungerz_prod
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      timeout: 20s
      retries: 10
      interval: 10s
      start_period: 40s

  # Queue Worker
  queue:
    build:
      context: .
      dockerfile: docker/php/Dockerfile
      args:
        user: laravel
        uid: 1000
    container_name: hungerz_queue_prod
    restart: unless-stopped
    working_dir: /var/www
    volumes:
      - ./:/var/www
      - ./docker/php/local.ini:/usr/local/etc/php/conf.d/local.ini
    command: sh -c "sleep 60 && php artisan queue:work --verbose --tries=3 --timeout=90"
    networks:
      - hungerz_prod
    depends_on:
      db:
        condition: service_healthy
      app:
        condition: service_started
    environment:
      - APP_ENV=production
      - APP_DEBUG=false

networks:
  hungerz_prod:
    driver: bridge

volumes:
  dbdata_prod:
    driver: local
COMPOSE_EOF

echo "🔨 Building containers..."
docker-compose -f docker-compose.prod.yml build --no-cache

echo "🌐 Configurando nginx temporário para SSL..."
cat > docker/nginx-prod/default.conf << EOF
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
    
    location / {
        return 301 https://\$host\$request_uri;
    }
}
EOF

echo "🐳 Subindo containers temporários..."
docker-compose -f docker-compose.prod.yml up -d webserver certbot

sleep 10

echo "🔒 Obtendo certificado SSL..."
docker-compose -f docker-compose.prod.yml exec certbot certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email $EMAIL \
    --agree-tos \
    --no-eff-email \
    -d $DOMAIN \
    -d www.$DOMAIN

if [ ! -d "docker/certbot/conf/live/$DOMAIN" ]; then
    echo "❌ Erro ao obter certificado SSL!"
    echo "Verifique se o domínio está apontando para este servidor"
    exit 1
fi

echo "✅ Certificado SSL obtido!"

# Parar containers temporários
docker-compose -f docker-compose.prod.yml down

echo "🔒 Configurando nginx com SSL..."
cat > docker/nginx-prod/default.conf << EOF
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
    
    location / {
        return 301 https://\$host\$request_uri;
    }
}

server {
    listen 443 ssl http2;
    server_name $DOMAIN www.$DOMAIN;
    
    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers off;
    
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    
    root /var/www/public;
    index index.php index.html;
    
    client_max_body_size 50M;
    
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }
    
    location ~ \.php\$ {
        try_files \$uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)\$;
        fastcgi_pass app:9000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param PATH_INFO \$fastcgi_path_info;
        fastcgi_param HTTPS on;
        fastcgi_read_timeout 240;
    }
    
    location ~ /\.(?!well-known).* {
        deny all;
    }
}
EOF

echo "🐳 Subindo todos os containers..."
docker-compose -f docker-compose.prod.yml up -d

echo "⏳ Aguardando MySQL..."
sleep 20

max_attempts=30
attempt=1
while [ $attempt -le $max_attempts ]; do
    if docker-compose -f docker-compose.prod.yml exec -T db mysqladmin ping -h localhost -u root -p${DB_ROOT_PASSWORD} 2>/dev/null; then
        echo "✅ MySQL pronto!"
        break
    fi
    sleep 2
    ((attempt++))
done

echo "📦 Instalando dependências..."
docker-compose -f docker-compose.prod.yml exec -T --user root app composer install --no-dev --optimize-autoloader --ignore-platform-reqs

echo "🔑 Gerando APP_KEY..."
docker-compose -f docker-compose.prod.yml exec -T app php artisan key:generate --force

echo "🔒 Configurando permissões..."
docker-compose -f docker-compose.prod.yml exec -T --user root app chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache
docker-compose -f docker-compose.prod.yml exec -T --user root app chmod -R 775 /var/www/storage /var/www/bootstrap/cache

echo "🗃️ Executando migrations..."
docker-compose -f docker-compose.prod.yml exec -T app php artisan migrate --force

echo "🌱 Executando seeders..."
docker-compose -f docker-compose.prod.yml exec -T app php artisan db:seed --force 2>/dev/null || echo "⚠️ Seeders não executados"

echo "🔗 Criando storage link..."
docker-compose -f docker-compose.prod.yml exec -T app php artisan storage:link 2>/dev/null || echo "⚠️ Storage link existente"

echo "⚡ Configurando cache..."
docker-compose -f docker-compose.prod.yml exec -T app php artisan config:cache
docker-compose -f docker-compose.prod.yml exec -T app php artisan view:cache

echo "🔄 Configurando renovação automática SSL..."
cat > /etc/cron.d/certbot-renew << EOF
0 12 * * * root cd $(pwd) && docker-compose -f docker-compose.prod.yml exec certbot certbot renew --quiet && docker-compose -f docker-compose.prod.yml exec webserver nginx -s reload
EOF

echo ""
echo "🎉 INSTALAÇÃO FRESCA CONCLUÍDA!"
echo ""
echo "🌐 Seu site: https://$DOMAIN"
echo "🔒 SSL: ✅ Configurado"
echo "🔄 Renovação: ✅ Automática"
echo ""
echo "🔧 Comandos úteis:"
echo "   docker-compose -f docker-compose.prod.yml logs app"
echo "   docker-compose -f docker-compose.prod.yml restart app"
echo ""