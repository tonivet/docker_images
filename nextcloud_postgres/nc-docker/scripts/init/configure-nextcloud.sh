
#!/bin/sh
set -eu

echo "Checking Nextcloud system configuration..."

set_if_missing() {
    name="$1"
    shift

    if php occ config:system:get "$name" >/dev/null 2>&1; then
        echo "$name is already configured; keeping existing value."
    else
        echo "Setting $name..."
        php occ config:system:set "$name" "$@"
    fi
}

set_if_missing default_phone_region \
    --value="$NC_DEFAULT_PHONE_REGION"

set_if_missing maintenance_window_start \
    --type=integer \
    --value="$NC_MAINTENANCE_WINDOW_START"

set_if_missing serverid \
    --value="$NC_SERVERID"

echo "Nextcloud system configuration check completed."