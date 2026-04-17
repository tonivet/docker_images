FROM nextcloud:latest

# Install supervisor to start multiple processes on container startup
# https://pkgs.alpinelinux.org/packages
RUN apt-get update \
    && apt-get install -y  \
      supervisor \
      vim \
      ffmpeg \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*

RUN mkdir "/var/log/supervisord"
RUN mkdir "/var/run/supervisord"

COPY supervisord.conf /
COPY --chmod=755 start_fulltextsearch_live.sh /
COPY --chmod=755 taskprocessing.sh /

# The install and update script is only triggered when a default command is used (apache-foreground or php-fpm).
# If you use a custom command you have to enable the install / update
# See https://github.com/nextcloud/docker
ENV NEXTCLOUD_UPDATE=1

CMD ["/usr/bin/supervisord", "-c", "/supervisord.conf"]