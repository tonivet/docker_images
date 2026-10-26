# to upgrade use: sudo docker compose build --no-cache

FROM nextcloud:latest

# Install supervisor to start multiple processes on container startup
# https://pkgs.alpinelinux.org/packages
RUN apt-get update \
    && apt-get install -y  \
      supervisor \
      vim \
      wget \
      ffmpeg \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*

# Suppress Apache ServerName warning
RUN echo "ServerName localhost" \
    > /etc/apache2/conf-available/servername.conf \
    && a2enconf servername

RUN mkdir "/var/log/supervisord"
RUN mkdir "/var/run/supervisord"

COPY supervisord.conf /
COPY --chmod=755 scripts/fulltextsearch_live.sh /
COPY --chmod=755 scripts/taskprocessing.sh /

# Create folder for post istalation scripts
RUN mkdir -p /docker-entrypoint-hooks.d/post-installation

# Add initial configuration script for phone region, maintanence hour and servier id
COPY --chmod=755 scripts/init/configure-nextcloud.sh \
    /docker-entrypoint-hooks.d/post-installation/configure-nextcloud.sh

COPY --chmod=755 scripts/init/install-notify-push.sh \
    /docker-entrypoint-hooks.d/post-installation/install-notify-push.sh

COPY --chmod=755 scripts/init/install-fulltextsearch.sh \
  /docker-entrypoint-hooks.d/post-installation/install-fulltextsearch.sh

# The install and update script is only triggered when a default command is used (apache-foreground or php-fpm).
# If you use a custom command you have to enable the install / update
# See https://github.com/nextcloud/docker
ENV NEXTCLOUD_UPDATE=1

CMD ["/usr/bin/supervisord", "-c", "/supervisord.conf"]