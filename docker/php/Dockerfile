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

# Instalar extensões PHP
RUN docker-php-ext-configure intl
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd zip intl

# Instalar Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Criar usuário do sistema para executar comandos do Composer e Artisan
RUN useradd -G www-data,root -u ${uid} -d /home/${user} ${user}
RUN mkdir -p /home/${user}/.composer && \
    chown -R ${user}:${user} /home/${user}

# Configurar diretório de trabalho
WORKDIR /var/www

# Copiar configurações customizadas do PHP
COPY docker/php/local.ini /usr/local/etc/php/conf.d/local.ini

# Trocar para o usuário criado
USER ${user}