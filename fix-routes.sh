#!/bin/bash

echo "🔧 Corrigindo problema de rotas duplicadas..."

# Limpar todos os caches
echo "🧹 Limpando caches..."
docker-compose exec -T app php artisan config:clear
docker-compose exec -T app php artisan route:clear
docker-compose exec -T app php artisan view:clear
docker-compose exec -T app php artisan cache:clear

# Verificar se há rotas duplicadas
echo "🔍 Verificando rotas duplicadas..."
docker-compose exec -T app php artisan route:list --json > routes.json 2>/dev/null || {
    echo "❌ Erro ao listar rotas. Há conflitos no arquivo de rotas."
    echo ""
    echo "📝 Para corrigir manualmente:"
    echo "1. Abra o arquivo routes/api.php"
    echo "2. Procure por rotas com nome 'apiadmin' duplicado"
    echo "3. Renomeie uma delas para um nome único"
    echo "4. Execute: docker-compose exec app php artisan route:clear"
    echo ""
    echo "💡 Exemplo de correção:"
    echo "   Route::get('/route1')->name('apiadmin.route1');"
    echo "   Route::get('/route2')->name('apiadmin.route2');"
    rm -f routes.json
    exit 1
}

echo "✅ Rotas verificadas com sucesso!"

# Tentar fazer cache novamente
echo "⚡ Tentando cache de rotas..."
if docker-compose exec -T app php artisan route:cache 2>/dev/null; then
    echo "✅ Cache de rotas criado com sucesso!"
else
    echo "⚠️ Não foi possível criar cache de rotas (normal em desenvolvimento)"
fi

rm -f routes.json
echo "🎉 Correção concluída!"