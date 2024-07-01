
This README is a tutorial, with the resulting code checked in for you to peruse.

We will not a use a database today, as that would require either:
- Another server, or
- Manual configuration on this server

# Prerequisites

Your machine, For Laravel:
- [Install Composer](https://getcomposer.org/doc/00-intro.md) on your machine.

Your Server, for Basic PHP Support:
- [Install piku](https://piku.github.io/install/index.html) on your server. If you have an SSH key configured during installation, that will be cloned for the new `piku` user.
- Install the [uwsgi-plugin-php](https://packages.debian.org/stable/web/uwsgi-plugin-php) package on your server, or equivalent.

Your Server, For Laravel:
- Install Composer on your server. You may consider the [composer package](https://packages.debian.org/bookworm/composer).
- Install the [npm package](https://packages.debian.org/bookworm/npm) on your server, or equivalent.
- Install the [php-xml package](https://packages.debian.org/bookworm/php-xml) on your server, or equivalent.
- Install the [php-sqlite3 package](https://packages.debian.org/bookworm/php7.4-sqlite3) on your server, or equivalent.

You may also consider the [php-mysql package](https://packages.debian.org/stable/php/php-mysql), although this tutorial does not use it.

```shell
apt install uwsgi-plugin-php composer npm php-xml php-sqlite3 php-mysql
```

# Create A New Laravel Install

On your local machine:

```shell
composer create-project laravel/laravel piku-php-laravel
cd piku-php-laravel
npm install
composer install
git init
git add .
git commit -m 'Initial commit.'
```

# Procfile
- Define the Piku "workers." You can read more about them [here](https://piku.github.io/configuration/procfile.html).
```
# The php worker allows us to interpret PHP scripts.
php: /public/

# Execute the Laravel cron job, which is currently recommended to run every minute:
# https://laravel.com/docs/11.x/homestead#configuring-cron-schedules
cron: * * * * * php artisan schedule:run

# Define our deployment script to run each time we push the website to the server.
release: ./deploy.sh
```

# `ENV`
- Define the Piku ENV variables. You can read more about them [here](https://piku.github.io/configuration/env.html)
- You can place your Laravel `.env` variables in this file also, but be aware that Laravel discourages checking passwords into your repo!
- Make sure you generate a random, 32-character APP_KEY for Laravel!
```
######
# Piku ENV Variables.
# Supplement the nginx configuration with our own directives.
NGINX_INCLUDE_FILE=nginx.conf

# We can define more than one domain or subdomain.
NGINX_SERVER_NAME=example.com www.example.com

######
# Laravel ENV Variables.  
# N.B. Laravel discourages the storage of these values in Git!
APP_NAME=Laravel
APP_ENV=local
APP_KEY=
APP_DEBUG=true
APP_TIMEZONE=UTC
APP_URL=http://localhost

APP_LOCALE=en
APP_FALLBACK_LOCALE=en
APP_FAKER_LOCALE=en_US

APP_MAINTENANCE_DRIVER=file
APP_MAINTENANCE_STORE=database

BCRYPT_ROUNDS=12

LOG_CHANNEL=stack
LOG_STACK=single
LOG_DEPRECATIONS_CHANNEL=null
LOG_LEVEL=debug

DB_CONNECTION=sqlite
# DB_HOST=127.0.0.1
# DB_PORT=3306
# DB_DATABASE=laravel
# DB_USERNAME=root
# DB_PASSWORD=

SESSION_DRIVER=database
SESSION_LIFETIME=120
SESSION_ENCRYPT=false
SESSION_PATH=/
SESSION_DOMAIN=null

BROADCAST_CONNECTION=log
FILESYSTEM_DISK=local
QUEUE_CONNECTION=database

CACHE_STORE=database
CACHE_PREFIX=

MEMCACHED_HOST=127.0.0.1

REDIS_CLIENT=phpredis
REDIS_HOST=127.0.0.1
REDIS_PASSWORD=null
REDIS_PORT=6379

MAIL_MAILER=log
MAIL_HOST=127.0.0.1
MAIL_PORT=2525
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_ENCRYPTION=null
MAIL_FROM_ADDRESS="hello@example.com"
MAIL_FROM_NAME="${APP_NAME}"

AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_DEFAULT_REGION=us-east-1
AWS_BUCKET=
AWS_USE_PATH_STYLE_ENDPOINT=false

VITE_APP_NAME="${APP_NAME}"
```

# `nginx.conf`
- This supplements the `nginx` configuration.
```nginx
# Let's redirect the www subdomain.
if ($host = www.example.com) {
	return 301 https://example.com$request_uri;
}

# Handle 404 errors through Laravel.
error_page 404 /index.php;
```

# `php.ini`
- Note that this overrides the default, system-wide `php.ini`configuration.
- If your server distro compiles PHP to supplement the `php.ini`file with a directory of scripts, those will still be read.
```ini
; Optional. Allow file uploads, and set the maximum file size.
file_uploads = On
upload_max_filesize = 1M
post_max_size = 1M

; If Laravel did not set this for us, we could set the timezone here also:
; date.timezone = "Europe/Lisbon"
  
; Enable Database Access With Sqlite3 (local file)
extension=pdo_sqlite  
extension=sqlite3
```

# `deploy.sh`
```shell
# Take the website offline for maintenance. Tell the browser to refresh every 15 seconds to check if we are back online yet.
php artisan down --refresh=15

# Clean up file permissions.
chmod -R 775 storage
find storage bootstrap -type f|xargs chmod -x

# Install checked-in dependencies (not latest).
npm ci
composer install --no-dev

# Build resource bundles for production.
npm run build

# Upgrade the database.
php artisan migrate

# Bring the website back online.
php artisan up
```

# Deploy to Piku

#### Add Piku Configuration to Git
```shell
# deploy.sh must be executable.
chmod +x deploy.sh
git add .
git commit -m 'Piku configuration.'
```

#### Push to server
```shell
git remote add prod piku@yourserver.net:laravel
git push prod
```

#### First Time Server Configuration
```shell
ssh piku@yourserver.net run laravel php artisan migrate
```

# Interact With Laravel Artisan

```shell
ssh piku@yourserver.net run laravel php artisan
```

# Start Over With Piku App

You can destroy the deployed app with a command like the following:

```shell
ssh piku@yourserver.net destroy laravel
```

# Debugging
#### Internal Server Error: No application encryption key has been specified.

You didn't read everything above, did you? Laravel requires you to generate your own 32-character `APP_KEY`.

You are also discouraged from saving this into your Git repo. For this quick demo, you can change the value in the `ENV` file.

#### Exposed Features
Piku exposes several features (like destroy) for managing your apps. You can request a list of supported options on your server via:

```shell
ssh piku@yourserver.net
```

#### Deeper Hacking
Your application is deployed under `/home/piku/.piku`, and is split into this structure:
- `acme` - SSL requests.
- `apps` - your checked-out application code.
- `cache` - Piku, various data.
- `data` - space for your application to save data.
- `envs` - Piku, scaling information
- `logs` - app start/stop logs. Access logs are found under `/var/log/nginx/`, or wherever they are configured for your linux distro.
- `nginx` - nginx configuration.
- `repos` - git repos for your apps.
- `uwsgi` - application server configuration.
- `uwsgi-available` - individual app configurations, if any.
- `uwsgi-enabled` - The enabled app configurations, if any.
