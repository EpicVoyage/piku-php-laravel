# The php worker allows us to interpret PHP scripts.
php: /public/

# Execute the Laravel cron job, which is currently recommended to run every minute:
# https://laravel.com/docs/11.x/homestead#configuring-cron-schedules
cron: * * * * * php artisan schedule:run

# Define our deployment script to run each time we push the website to the server.
release: ./deploy.sh
