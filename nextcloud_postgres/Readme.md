# Nextcloud Docker Stack

This project deploys Nextcloud with PostgreSQL and Redis, plus supporting services for push notifications, full-text search, previews, Office, Whiteboard, Talk, and other integrations. The Nextcloud image is built from the custom Dockerfile in `nc-docker/`.

## Requirements

- Docker Engine with the Docker Compose plugin
- A `.env` file in this directory with the variables listed below
- An existing external Docker network named `nextcloud`, shared with Traefik
- DNS records for the configured domains pointing to the Traefik host, and Traefik configured to use the `websecure` entrypoint and `production` certificate resolver
- NVIDIA GPU-enabled Docker support for the `gpus: all` setting on the Nextcloud service

Create the shared network if it does not already exist:

```sh
docker network create nextcloud
```

If Traefik uses a different Docker network, update the Compose network configuration and the services' `traefik.docker.network` labels to match.

## Configuration

Set these variables in `.env`. Use strong, unique values for passwords and secrets. Do not commit `.env` to source control.

| Variable | Purpose |
| --- | --- |
| `NC_DOMAIN` | Public Nextcloud hostname, without `https://` |
| `NC_ADMIN_USER` | Initial Nextcloud administrator username |
| `NC_ADMIN_PASSWORD` | Initial Nextcloud administrator password |
| `POSTGRES_PASSWORD` | PostgreSQL password used by Nextcloud and the database |
| `REDIS_PASSWORD` | Redis password used by Nextcloud and supporting services |
| `TIMEZONE` | Time zone for services that accept `TZ` |
| `NC_DEFAULT_PHONE_REGION` | Default phone region; defaults to `BG` |
| `NC_MAINTENANCE_WINDOW_START` | Maintenance window start hour; defaults to `3` |
| `NC_SERVERID` | Nextcloud server ID; defaults to `nextcloud01` |
| `HP_SHARED_KEY` | Shared key for the AppAPI HaRP service |
| `EUROOFFICE_DOMAIN` | Public hostname routed to EuroOffice |
| `JWT_SECRET` | EuroOffice JWT secret |
| `WHITEBOARD_SECRET_KEY` | Whiteboard JWT secret |
| `TURN_SECRET_KEY` | Talk TURN secret |
| `SIGNALING_SECRET_KEY` | Talk signaling secret |
| `INTERNAL_SECRET_KEY` | Shared internal secret for Talk services |
| `RECORDING_SECRET_KEY` | Talk recording secret |

Compose reads `.env` for variable substitution. Keep `NC_DOMAIN` and `EUROOFFICE_DOMAIN` as hostnames; the Compose labels configure HTTPS through Traefik.

## Start the stack

From this directory, build the custom Nextcloud image and start the services:

```sh
docker compose up -d --build
```

Check service status and logs:

```sh
docker compose ps
docker compose logs -f nextcloud
```

Nextcloud is served at `https://${NC_DOMAIN}`. Traefik routes the integrations on the same host using `/push`, `/whiteboard`, `/signaling`, and `/recording`; EuroOffice is served at `https://${EUROOFFICE_DOMAIN}`. Talk also publishes TCP and UDP port `3479` on the Docker host, which must be allowed through the host firewall and router for TURN traffic.

## First startup

The image's post-installation hooks configure the phone region, maintenance window, and server ID when those settings are missing. They also install and configure Notify Push and the Full Text Search apps. The Notify Push hook waits for the `nc-notify-push` server to become reachable; full-text search is configured to use `nc-fulltext-search`.

Once the services are running, initial full-text indexing can be started with:

```sh
docker compose exec -u www-data nextcloud php occ fulltextsearch:test
docker compose exec -u www-data nextcloud php occ fulltextsearch:index
```

Some integrations need to be enabled or configured in Nextcloud's administration settings. In particular, install/enable the Office, Whiteboard, Talk, Antivirus, or AppAPI apps as needed, then set their corresponding service URLs or secrets. The related comments in `docker-compose.yml` describe the expected URLs and settings.

## Administration

Run Nextcloud's `occ` command inside the container:

```sh
docker compose exec -u www-data nextcloud php occ status
docker compose exec -u www-data nextcloud php occ app:list
```

Rebuild the custom image after changing `nc-docker/`:

```sh
docker compose build nextcloud
docker compose up -d nextcloud
```

The stack stores application data, database data, Redis data, search indexes, and integration data in named Docker volumes declared at the bottom of `docker-compose.yml`. Back up these volumes and the `.env` file before upgrades or migrations. Removing volumes destroys persistent application data; do not use `docker compose down -v` for routine shutdowns.

## Services

- `nextcloud`: Custom Nextcloud image, Apache, cron, live full-text indexing, and four background task workers under Supervisor.
- `nc-db` and `nc-redis`: PostgreSQL database and password-protected Redis instance.
- `nc-notify-push` and `fulltextsearch`: Push notifications and Elasticsearch-backed full-text search.
- `nc-imaginary`: Image preview generation service.
- `nc-harp` and `nc-eurooffice`: AppAPI HaRP and EuroOffice document server.
- `nc-whiteboard`, `nc-talk`, and `nc-talk-recording`: Whiteboard and Talk signaling/recording services.
- `nc-clamav`: ClamAV daemon for use with Nextcloud's Antivirus for files app.