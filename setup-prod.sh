#!/bin/bash

echo "🚀 Configurando ambiente Hungerz para PRODUÇÃO com HTTPS..."

# Verificar se está rodando como root ou com sudo
if [ "$EUID" -ne 0 ]; then
    echo "❌ Este script precisa ser executado como root ou com sudo"
    echo "Execute: sudo ./setup-prod.sh"
    exit 1
fi

# Verificar parâmetros obrigatórios
if [ -z "$1" ]; then
    echo "❌ Uso: sudo ./setup-prod.sh SEU_DOMINIO.com [EMAIL]"
    echo "Exemplo: sudo ./setup-prod.sh hungerz.com admin@hungerz.com"
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
    echo "❌ Projeto Hungerz não encontrado neste diretório!"
    echo "Por favor, execute este script na raiz do projeto Hungerz."
    exit 1
else
    echo "✅ Projeto Hungerz encontrado!"
fi

# Atualizar sistema
echo "🔄 Atualizando sistema..."
apt-get update && apt-get upgrade -y

# Instalar Docker e Docker Compose se não existir
if ! command -v docker &> /dev/null; then
    echo "🐳 Instalando Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
    systemctl enable docker
    systemctl start docker
fi

if ! command -v docker-compose &> /dev/null; then
    echo "🐳 Instalando Docker Compose..."
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
fi

# Parar containers existentes
echo "🛑 Parando containers existentes..."
docker-compose -f docker-compose.prod.yml down 2>/dev/null || true

# Criar diretórios necessários
mkdir -p docker/nginx-prod
mkdir -p docker/certbot/conf
mkdir -p docker/certbot/www

# Verificar se .env existe e configurar para produção
if [ ! -f ".env" ]; then
    echo "📋 Criando arquivo .env baseado no template..."
    cp .env.example .env
fi

echo "⚙️ Configurando .env para produção..."
# Ajustar configurações importantes para produção
sed -i "s/APP_ENV=.*/APP_ENV=production/" .env
sed -i "s/APP_DEBUG=.*/APP_DEBUG=false/" .env
sed -i "s/APP_URL=.*/APP_URL=https:\/\/$DOMAIN/" .env
sed -i "s/SESSION_SECURE_COOKIE=.*/SESSION_SECURE_COOKIE=true/" .env

echo "🔐 Gerando chave da aplicação se necessário..."
if ! grep -q "APP_KEY=base64:" .env; then
    # Gerar temporariamente a key usando container
    docker run --rm -v $(pwd):/var/www -w /var/www composer:latest composer install --no-dev --optimize-autoloader
    docker run --rm -v $(pwd):/var/www -w /var/www php:8.2-cli php artisan key:generate
fi

# Build das imagens
echo "🔨 Building imagens Docker para produção..."
docker-compose -f docker-compose.prod.yml build --no-cache

# Configurar nginx temporário para validação do domínio
echo "🌐 Configurando nginx temporário para validação SSL..."
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

# Subir containers sem SSL primeiro
echo "🐳 Subindo containers temporários..."
docker-compose -f docker-compose.prod.yml up -d webserver certbot

# Aguardar nginx iniciar
echo "⏳ Aguardando nginx iniciar..."
sleep 10

# Obter certificado SSL
echo "🔒 Obtendo certificado SSL do Let's Encrypt..."
docker-compose -f docker-compose.prod.yml exec certbot certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email $EMAIL \
    --agree-tos \
    --no-eff-email \
    -d $DOMAIN \
    -d www.$DOMAIN

# Verificar se certificado foi criado
if [ ! -d "docker/certbot/conf/live/$DOMAIN" ]; then
    echo "❌ Erro ao obter certificado SSL!"
    echo "🔧 Verifique se:"
    echo "   - O domínio $DOMAIN está apontando para este servidor"
    echo "   - As portas 80 e 443 estão abertas"
    echo "   - Não há firewall bloqueando"
    exit 1
fi

echo "✅ Certificado SSL obtido com sucesso!"

# Parar containers temporários
docker-compose -f docker-compose.prod.yml down

# Configurar nginx com SSL
echo "🔒 Configurando nginx com SSL..."
cat > docker/nginx-prod/default.conf << EOF
# Redirect HTTP to HTTPS
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

# HTTPS Server
server {
    listen 443 ssl http2;
    server_name $DOMAIN www.$DOMAIN;
    
    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
    
    # SSL Security Headers
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers off;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
    
    # Security Headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    
    # Logs
    error_log  /var/log/nginx/error.log;
    access_log /var/log/nginx/access.log;
    
    # Document root
    root /var/www/public;
    index index.php index.html;
    
    # Client upload limit (adjust as needed)
    client_max_body_size 50M;
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied expired no-cache no-store private must-revalidate auth;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss;
    
    # Main location
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
        gzip_static on;
    }
    
    # PHP processing
    location ~ \.php\$ {
        try_files \$uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)\$;
        fastcgi_pass app:9000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param PATH_INFO \$fastcgi_path_info;
        fastcgi_param HTTPS on;
        fastcgi_buffer_size 128k;
        fastcgi_buffers 256 16k;
        fastcgi_busy_buffers_size 256k;
        fastcgi_temp_file_write_size 256k;
        fastcgi_read_timeout 240;
    }
    
    # Security: deny access to hidden files
    location ~ /\.(?!well-known).* {
        deny all;
    }
    
    # Static files caching
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|pdf|txt|tar|gz)\$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF

# Subir todos os containers com SSL
echo "🐳 Subindo containers de produção com SSL..."
docker-compose -f docker-compose.prod.yml up -d

# Aguardar containers iniciarem
echo "⏳ Aguardando containers iniciarem..."
sleep 15

# Verificar se o banco está pronto
echo "🔍 Verificando se MySQL está pronto..."
max_attempts=60
attempt=1

while [ $attempt -le $max_attempts ]; do
    echo "🔍 Tentativa $attempt/$max_attempts - Verificando MySQL..."
    
    if docker-compose -f docker-compose.prod.yml exec -T db mysqladmin ping -h localhost -u root -proot 2>/dev/null; then
        echo "✅ MySQL está pronto!"
        break
    fi
    
    sleep 2
    ((attempt++))
done

if [ $attempt -gt $max_attempts ]; then
    echo "❌ Erro: MySQL não ficou pronto após $max_attempts tentativas"
    exit 1
fi

# Instalar dependências de produção
echo "📦 Instalando dependências do Composer para produção..."
docker-compose -f docker-compose.prod.yml exec -T app composer install --no-dev --optimize-autoloader

# Executar migrations
echo "🗃️ Executando migrations..."
docker-compose -f docker-compose.prod.yml exec -T app php artisan migrate --force

# Executar seeders se necessário
echo "🌱 Verificando seeders..."
if docker-compose -f docker-compose.prod.yml exec -T app php artisan db:seed --force 2>/dev/null; then
    echo "✅ Seeders executados"
fi

# Configurar permissões
echo "🔒 Configurando permissões..."
docker-compose -f docker-compose.prod.yml exec -T --user root app chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache

# Cache de produção
echo "⚡ Configurando cache de produção..."
docker-compose -f docker-compose.prod.yml exec -T app php artisan config:cache
docker-compose -f docker-compose.prod.yml exec -T app php artisan route:cache
docker-compose -f docker-compose.prod.yml exec -T app php artisan view:cache

# Configurar renovação automática do certificado
echo "🔄 Configurando renovação automática do certificado..."
cat > /etc/cron.d/certbot-renew << EOF
0 12 * * * root cd $(pwd) && docker-compose -f docker-compose.prod.yml exec certbot certbot renew --quiet && docker-compose -f docker-compose.prod.yml exec webserver nginx -s reload
EOF

echo ""
echo "🎉 Ambiente Hungerz PRODUÇÃO configurado com sucesso!"
echo ""
echo "📋 Serviços disponíveis:"
echo "   🍔 Aplicação Hungerz: https://$DOMAIN"
echo "   🔒 Certificado SSL: ✅ Configurado"
echo "   🔄 Renovação automática: ✅ Configurada"
echo ""
echo "🔧 Comandos úteis para produção:"
echo "   docker-compose -f docker-compose.prod.yml exec app php artisan [comando]"
echo "   docker-compose -f docker-compose.prod.yml logs -f [serviço]"
echo "   docker-compose -f docker-compose.prod.yml restart [serviço]"
echo ""
echo "⚠️ IMPORTANTE - SEGURANÇA:"
echo "   ✅ Remova o PHPMyAdmin em produção se não precisar"
echo "   ✅ Configure firewall (ufw) para permitir apenas 80, 443 e 22"
echo "   ✅ Altere senhas padrão no .env"
echo "   ✅ Configure backup do banco de dados"
echo "   ✅ Monitor logs regularmente"
echo ""
echo "🔐 Teste seu SSL em: https://www.ssllabs.com/ssltest/analyze.html?d=$DOMAIN"
echo ""