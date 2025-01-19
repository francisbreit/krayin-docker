# Etapa 1: Build - usando uma imagem base do PHP com extensões necessárias para Laravel
FROM php:8.3-fpm AS build

# Instalação de dependências do sistema
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libwebp-dev \
    libzip-dev \
    libonig-dev \
    zlib1g-dev \
    libxml2-dev \
    curl \
    && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install gd pdo pdo_mysql mbstring zip bcmath opcache calendar

# Instalar o Composer
COPY --from=composer:2.7 /usr/bin/composer /usr/local/bin/composer

# Adicionar Node.js para o front-end (se necessário para Krayin)
COPY --from=node:20 /usr/local/bin/ /usr/local/bin/
COPY --from=node:20 /usr/local/lib/ /usr/local/lib/

# Argumentos para configurar o ambiente de desenvolvimento
ARG APP_ENV=production
ARG APP_DEBUG=false

# Adicionar usuário não root
RUN useradd -ms /bin/bash laravel

# Definir o diretório de trabalho
WORKDIR /var/www/html

# Copiar os arquivos do Laravel
COPY . .

# Instalar dependências do Laravel
RUN composer install --no-dev --optimize-autoloader \
    && php artisan storage:link \
    && php artisan cache:clear \
    && php artisan config:clear \
    && php artisan view:clear \
    && chmod -R 775 storage bootstrap/cache \
    && chown -R laravel:www-data /var/www/html

# Etapa 2: Produção - com a aplicação preparada
FROM php:8.3-fpm

# Copiar arquivos da etapa de build
COPY --from=build /var/www/html /var/www/html

# Definir permissões para o container
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

# Configurar diretório de trabalho
WORKDIR /var/www/html

# Expor a porta 9000 do PHP-FPM
EXPOSE 9000

# Iniciar o PHP-FPM
CMD ["php-fpm"]
