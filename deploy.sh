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
