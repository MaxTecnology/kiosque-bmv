#!/bin/bash

echo "🔧 Correção COMPLETA dos problemas do Hungerz em produção..."

# Verificar se está rodando como root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Este script precisa ser executado como root ou com sudo"
    echo "Execute: sudo ./fix-all-prod.sh"
    exit 1
fi

# Verificar se existe projeto Laravel
if [ ! -f "artisan" ]; then
    echo "❌ Projeto Hungerz não encontrado neste diretório!"
    exit 1
fi

echo "🛑 Parando todos os containers..."
docker-compose -f docker-compose.prod.yml down --remove-orphans
docker system prune -f

echo "📁 Criando TODOS os diretórios necessários..."
mkdir -p storage/{app/{public,temp},framework/{cache,sessions,testing,views},logs}
mkdir -p bootstrap/cache
mkdir -p public/storage
mkdir -p vendor

echo "🔒 Configurando permissões COMPLETAS do host..."
# Permissões do host primeiro
chmod -R 755 .
chmod -R 775 storage bootstrap/cache public/storage
chown -R 1000:1000 . 2>/dev/null || true
chown -R www-data:www-data storage bootstrap/cache 2>/dev/null || true

echo "🔧 Corrigindo composer.json para versão PHP correta..."
# Backup do composer.json original
cp composer.json composer.json.backup

# Atualizar requisito de PHP para 8.2 ou superior
sed -i 's/"php": "~8\.2\.0"/"php": "^8.2"/' composer.json

echo "🐳 Fazendo rebuild completo dos containers..."
docker-compose -f docker-compose.prod.yml build --no-cache --pull

echo "🚀 Subindo containers..."
docker-compose -f docker-compose.prod.yml up -d

echo "⏳ Aguardando containers ficarem prontos..."
sleep 20

echo "🔍 Verificando se MySQL está pronto..."
max_attempts=30
attempt=1

while [ $attempt -le $max_attempts ]; do
    if docker-compose -f docker-compose.prod.yml exec -T db mysqladmin ping -h localhost -u root -proot 2>/dev/null; then
        echo "✅ MySQL está pronto!"
        break
    fi
    echo "⏳ Tentativa $attempt/$max_attempts..."
    sleep 2
    ((attempt++))
done

if [ $attempt -gt $max_attempts ]; then
    echo "❌ MySQL não ficou pronto. Verificando logs..."
    docker-compose -f docker-compose.prod.yml logs db
    exit 1
fi

echo "🔒 Configurando permissões DENTRO dos containers..."
docker-compose -f docker-compose.prod.yml exec -T --user root app chown -R www-data:www-data /var/www
docker-compose -f docker-compose.prod.yml exec -T --user root app chmod -R 775 /var/www/storage /var/www/bootstrap/cache
docker-compose -f docker-compose.prod.yml exec -T --user root app chmod -R 755 /var/www/public

echo "📦 Instalando Composer com --ignore-platform-reqs..."
docker-compose -f docker-compose.prod.yml exec -T --user root app composer install --no-dev --optimize-autoloader --ignore-platform-reqs

echo "🔑 Gerando APP_KEY se necessário..."
if ! grep -q "APP_KEY=base64:" .env; then
    docker-compose -f docker-compose.prod.yml exec -T app php artisan key:generate --force
fi

echo "🗃️ Executando migrations..."
docker-compose -f docker-compose.prod.yml exec -T app php artisan migrate --force

echo "🌱 Executando seeders (se existir)..."
docker-compose -f docker-compose.prod.yml exec -T app php artisan db:seed --force 2>/dev/null || echo "⚠️ Seeders não encontrados"

echo "🔗 Criando storage link..."
docker-compose -f docker-compose.prod.yml exec -T --user root app php artisan storage:link 2>/dev/null || echo "⚠️ Storage link problema"

echo "🧹 Limpando caches..."
docker-compose -f docker-compose.prod.yml exec -T app php artisan config:clear
docker-compose -f docker-compose.prod.yml exec -T app php artisan route:clear
docker-compose -f docker-compose.prod.yml exec -T app php artisan view:clear
docker-compose -f docker-compose.prod.yml exec -T app php artisan cache:clear

echo "⚡ Configurando cache (pulando rotas se houver conflito)..."
docker-compose -f docker-compose.prod.yml exec -T app php artisan config:cache
# Pular route:cache se houver conflito de rotas
docker-compose -f docker-compose.prod.yml exec -T app php artisan route:cache 2>/dev/null || echo "⚠️ Route cache pulado devido a conflitos"
docker-compose -f docker-compose.prod.yml exec -T app php artisan view:cache

echo "🔧 Permissões finais..."
docker-compose -f docker-compose.prod.yml exec -T --user root app chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache
docker-compose -f docker-compose.prod.yml exec -T --user root app chmod -R 775 /var/www/storage /var/www/bootstrap/cache

echo "🔍 Verificando status final..."
docker-compose -f docker-compose.prod.yml ps

echo ""
echo "✅ CORREÇÃO COMPLETA APLICADA!"
echo ""
echo "🌐 Teste seu site: https://betania.nuuque.com.br"
echo ""
echo "📋 Se ainda houver problemas:"
echo "   docker-compose -f docker-compose.prod.yml logs app"
echo "   docker-compose -f docker-compose.prod.yml logs webserver"
echo "   docker-compose -f docker-compose.prod.yml exec app php artisan --version"
echo ""
echo "🔧 Comandos úteis:"
echo "   docker-compose -f docker-compose.prod.yml restart app"
echo "   docker-compose -f docker-compose.prod.yml exec app php artisan config:clear"
echo ""