#!/bin/bash

echo "🍔 Configurando ambiente Hungerz com Docker..."

# Criar estrutura de diretórios
mkdir -p docker/php
mkdir -p docker/nginx
mkdir -p docker/mysql

# Verificar se existe projeto Laravel
if [ ! -f "artisan" ]; then
    echo "❌ Projeto Hungerz não encontrado neste diretório!"
    echo "Por favor, execute este script na raiz do projeto Hungerz."
    exit 1
else
    echo "✅ Projeto Hungerz encontrado!"
fi

# Parar containers existentes
echo "🛑 Parando containers existentes..."
docker-compose down

# Verificar se .env existe
if [ ! -f ".env" ]; then
    echo "📋 Criando arquivo .env baseado no template..."
    cp .env.example .env
    echo "⚠️ Lembre-se de ajustar as configurações no .env conforme necessário!"
else
    echo "✅ Arquivo .env encontrado!"
fi

# Build das imagens
echo "🔨 Building imagens Docker..."
docker-compose build --no-cache

# Subir containers
echo "🐳 Subindo containers Docker..."
docker-compose up -d

# Aguardar containers iniciarem
echo "⏳ Aguardando containers iniciarem..."
sleep 10

# Verificar se o banco está pronto
echo "🔍 Verificando se MySQL está pronto..."
max_attempts=60
attempt=1

while [ $attempt -le $max_attempts ]; do
    echo "🔍 Tentativa $attempt/$max_attempts - Verificando MySQL..."
    
    if docker-compose exec -T db mysqladmin ping -h localhost -u root -proot 2>/dev/null; then
        echo "✅ MySQL está pronto!"
        break
    fi
    
    sleep 2
    ((attempt++))
done

if [ $attempt -gt $max_attempts ]; then
    echo "❌ Erro: MySQL não ficou pronto após $max_attempts tentativas"
    echo "🔧 Troubleshooting:"
    echo "   docker-compose logs db"
    echo "   docker-compose ps"
    exit 1
fi

# Verificar/criar banco hungerz
echo "🗃️ Verificando banco hungerz..."
docker-compose exec -T db mysql -u root -proot -e "CREATE DATABASE IF NOT EXISTS hungerz;" 2>/dev/null
docker-compose exec -T db mysql -u root -proot -e "GRANT ALL PRIVILEGES ON hungerz.* TO 'laravel'@'%'; FLUSH PRIVILEGES;" 2>/dev/null

# Instalar dependências
echo "📦 Instalando dependências do Composer..."
docker-compose exec -T app composer install --no-dev --optimize-autoloader

# Limpar caches antes das migrations
echo "🧹 Limpando caches..."
docker-compose exec -T app php artisan config:clear
docker-compose exec -T app php artisan route:clear
docker-compose exec -T app php artisan view:clear
docker-compose exec -T app php artisan cache:clear

# Executar migrations
echo "🗃️ Executando migrations..."
docker-compose exec -T app php artisan migrate --force

# Executar seeders se existir
echo "🌱 Verificando seeders..."
if docker-compose exec -T app php -r "class_exists('DatabaseSeeder') ? exit(0) : exit(1);"; then
    echo "🌱 Executando seeders..."
    docker-compose exec -T app php artisan db:seed --force
else
    echo "ℹ️ Nenhum seeder encontrado"
fi

# Configurar permissões (executar como root)
echo "🔒 Configurando permissões..."
docker-compose exec -T --user root app chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache 2>/dev/null || true

# Criar link do storage se não existir
echo "🔗 Verificando link do storage..."
if [ ! -L "public/storage" ]; then
    docker-compose exec -T app php artisan storage:link
else
    echo "✅ Link do storage já existe"
fi

# Cache de configurações (apenas se não houver conflitos de rota)
echo "⚡ Tentando otimizar cache..."
docker-compose exec -T app php artisan config:cache 2>/dev/null || echo "⚠️ Config cache pulado devido a conflitos"
docker-compose exec -T app php artisan view:cache 2>/dev/null || echo "⚠️ View cache pulado"

echo ""
echo "🎉 Ambiente Hungerz configurado com sucesso!"
echo ""
echo "📋 Serviços disponíveis:"
echo "   🍔 Aplicação Hungerz: http://localhost:8000"
echo "   📧 MailHog (teste emails): http://localhost:8025"
echo "   🗄️ PHPMyAdmin: http://localhost:8080"
echo "   🗃️ MySQL: localhost:3306 (user: laravel, pass: laravel)"
echo "   ⚡ Redis: localhost:6379"
echo ""
echo "🔧 Comandos úteis:"
echo "   docker-compose exec app php artisan [comando]"
echo "   docker-compose exec app composer [comando]"
echo "   docker-compose logs -f [serviço]"
echo "   docker-compose restart [serviço]"
echo ""
echo "🐛 Troubleshooting:"
echo "   docker-compose logs app    # Ver logs da aplicação"
echo "   docker-compose logs db     # Ver logs do banco"
echo "   docker-compose exec app php artisan config:clear  # Limpar cache"
echo ""
echo "⚠️ Importante:"
echo "   - Se houver erro de rotas duplicadas, verifique routes/api.php"
echo "   - Ajuste as configurações de pagamento no .env"
echo "   - Configure Firebase e OneSignal se necessário"
echo ""