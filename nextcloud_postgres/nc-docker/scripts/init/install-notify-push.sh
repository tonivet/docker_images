#!/bin/sh
set -eu

: "${NC_DOMAIN:?NC_DOMAIN is not set}"

PUSH_URL="https://${NC_DOMAIN}/push"
PUSH_HOST="nc-notify-push"
PUSH_PORT="7867"
MAX_ATTEMPTS=30
ATTEMPT=0

if ! php occ app:list | grep -q 'notify_push:'; then
    php occ app:install notify_push
fi

php occ config:system:set trusted_domains 2 \
    --value="nc" # nextcloud container name
echo "nextcloud container added to trusted domains"

php occ config:system:set overwrite.cli.url \
    --value="https://${NC_DOMAIN}"
echo "overwrite.cli.url added"


echo "Waiting for Notify Push server..."

while [ "$ATTEMPT" -lt "$MAX_ATTEMPTS" ]; do
    if php -r '
        $socket = @fsockopen($argv[1], (int)$argv[2], $errno, $errstr, 2);
        if ($socket) {
            fclose($socket);
            exit(0);
        }
        exit(1);
    ' "$PUSH_HOST" "$PUSH_PORT"; then
        break
    fi

    ATTEMPT=$((ATTEMPT + 1))
    echo "Notify Push is not ready yet ($ATTEMPT/$MAX_ATTEMPTS)..."
    sleep 2
done

if [ "$ATTEMPT" -eq "$MAX_ATTEMPTS" ]; then
    echo "ERROR: Notify Push server did not become reachable."
    exit 1
fi

echo "Notify Push server is reachable."
echo "Configuring Notify Push endpoint: $PUSH_URL"

php occ notify_push:setup "$PUSH_URL"

echo "Notify Push setup completed."