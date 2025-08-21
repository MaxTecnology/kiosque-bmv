#!/bin/bash

echo "🔧 Corrigindo problemas de permissões e composer no Hungerz..."

# Verificar se está rodando como root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Este script precisa ser executado como root ou com sudo"
    echo "Execute: sudo ./fix-prod.sh"
    exit 1
fi

# Verificar se existe projeto Laravel
if [ ! -f "artisan" ]; then
    echo "❌ Projeto Hungerz não encontrado neste diretório!"
    exit 1
fi

echo "🛑 Parando containers para corrigir..."
docker-compose -f docker-compose.prod.yml down

echo "📁 Criando diretórios necessários do Laravel..."
mkdir -p storage/app/public
mkdir -p storage/framework/cache
mkdir -p storage/framework/sessions  
mkdir -p storage/framework/testing
mkdir -p storage/framework/views
mkdir -p storage/logs
mkdir -p bootstrap/cache
mkdir -p public/storage

echo "🔒 Configurando permissões do sistema de arquivos..."
# Permissões básicas
chmod -R 755 storage bootstrap/cache public
chmod -R 775 storage/logs storage/framework
chown -R www-data:www-data storage bootstrap/cache 2>/dev/null || true
chown -R 1000:1000 . 2>/dev/null || true

echo "🐳 Subindo containers novamente..."
docker-compose -f docker-compose.prod.yml up -d

echo "⏳ Aguardando containers iniciarem..."
sleep 15

echo "📦 Instalando dependências do Composer com permissões corretas..."
docker-compose -f docker-compose.prod.yml exec -T --user root app composer install --no-dev --optimize-autoloader

echo "🔒 Configurando permissões dos containers..."
docker-compose -f docker-compose.prod.yml exec -T --user root app chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache
docker-compose -f docker-compose.prod.yml exec -T --user root app chmod -R 775 /var/www/storage /var/www/bootstrap/cache
docker-compose -f docker-compose.prod.yml exec -T --user root app chmod -R 755 /var/www/public

echo "🗃️ Executando migrations..."
docker-compose -f docker-compose.prod.yml exec -T app php artisan migrate --force

echo "🌱 Executando seeders..."
docker-compose -f docker-compose.prod.yml exec -T app php artisan db:seed --force 2>/dev/null || echo "⚠️ Seeders não encontrados ou já executados"

echo "🔗 Configurando link do storage..."
docker-compose -f docker-compose.prod.yml exec -T app php artisan storage:link || echo "⚠️ Storage link já existe"

echo "🧹 Limpando caches antigos..."
docker-compose -f docker-compose.prod.yml exec -T app php artisan config:clear
docker-compose -f docker-compose.prod.yml exec -T app php artisan route:clear  
docker-compose -f docker-compose.prod.yml exec -T app php artisan view:clear
docker-compose -f docker-compose.prod.yml exec -T app php artisan cache:clear

echo "⚡ Configurando cache de produção..."
docker-compose -f docker-compose.prod.yml exec -T app php artisan config:cache
docker-compose -f docker-compose.prod.yml exec -T app php artisan route:cache
docker-compose -f docker-compose.prod.yml exec -T app php artisan view:cache

echo "🔍 Verificando status dos containers..."
docker-compose -f docker-compose.prod.yml ps

echo ""
echo "✅ Correções aplicadas com sucesso!"
echo ""
echo "🔧 Teste seu site agora:"
echo "   https://betania.nuuque.com.br"
echo ""
echo "📋 Se ainda houver problemas, verifique os logs:"
echo "   docker-compose -f docker-compose.prod.yml logs app"
echo "   docker-compose -f docker-compose.prod.yml logs webserver"
echo ""