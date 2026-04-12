#!/bin/sh
echo "Starting Nextcloud AI Worker $1"
# this is only needed if you want to use local AI for Nextlcoud as ollama. Without it AI will answer once in evry 5 minutes
php /var/www/html/occ background-job:worker -t 30 'OC\TaskProcessing\SynchronousBackgroundJob'