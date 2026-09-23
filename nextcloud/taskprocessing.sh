#!/bin/sh
echo "Starting Nextcloud AI Worker $1"
# this is needed if you want to use ollama as local AI agent for nextcloud. Without it AI will answer once in evry 5 minutes.
while true; do
  php /var/www/html/occ taskprocessing:worker -v -t 60
  sleep 1
done