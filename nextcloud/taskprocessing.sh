#!/bin/sh
echo "Starting Nextcloud AI Worker $1"
php /var/www/html/occ background-job:worker -t 30 'OC\TaskProcessing\SynchronousBackgroundJob'