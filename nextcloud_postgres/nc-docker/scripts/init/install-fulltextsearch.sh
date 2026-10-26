#!/bin/sh
set -eu

echo "Checking Nextcloud Full Text Search apps..."

install_app_if_missing() {
    app_id="$1"

    if php occ app:list --output=json | php -r '
        $apps = json_decode(stream_get_contents(STDIN), true);
        $id = $argv[1];
        exit(
            isset($apps["enabled"][$id]) ||
            isset($apps["disabled"][$id]) ? 0 : 1
        );
    ' "$app_id"; then
        echo "$app_id is already installed."
    else
        echo "Installing $app_id..."
        php occ app:install "$app_id"
    fi

    echo "Ensuring $app_id is enabled..."
    php occ app:enable "$app_id"
}

install_app_if_missing fulltextsearch
install_app_if_missing fulltextsearch_elasticsearch
install_app_if_missing files_fulltextsearch

echo "Configuring Full Text Search..."

php occ config:app:set fulltextsearch search_platform \
    --value='OCA\FullTextSearch_Elasticsearch\Platform\ElasticSearchPlatform'

php occ config:app:set fulltextsearch enabled \
    --value="yes"

php occ config:app:set fulltextsearch_elasticsearch elastic_host \
    --value="http://nc-fulltext-search:9200"

php occ config:app:set fulltextsearch_elasticsearch elastic_index \
    --value="nextcloud"

php occ config:app:set fulltextsearch_elasticsearch analyzer_tokenizer \
    --value="standard"

php occ config:app:set fulltextsearch_elasticsearch enabled \
    --value="yes"

echo "Full Text Search installation and configuration completed."
echo "test the configration with: php occ fulltextsearch:test and"
echo "and after that run initial indexing with: php occ fulltextsearch:index"
