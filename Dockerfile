FROM tarpha/torrssen2

ENV PUID 0
ENV PGID 100

# Install packages
RUN apk update && \
    apk add --no-cache \
    transmission-daemon \
    nginx \
    php7 \
    php7-fpm \
    php7-openssl \
    php7-curl

# Transmission
RUN mkdir -p /config

# Nginx
RUN adduser -D -g 'www' www && \
    mkdir -p /www/torr /run/nginx && \
    chown -R www:www /var/lib/nginx /www

# PHP7
ENV PHP_FPM_USER "www"
ENV PHP_FPM_GROUP "www"
ENV PHP_FPM_LISTEN_MODE "0660"
ENV PHP_MEMORY_LIMIT "512M"
ENV PHP_MAX_UPLOAD "50M"
ENV PHP_MAX_FILE_UPLOAD "200"
ENV PHP_MAX_POST "100M"
ENV PHP_DISPLAY_ERRORS "On"
ENV PHP_DISPLAY_STARTUP_ERRORS "On"
ENV PHP_ERROR_REPORTING "E_COMPILE_ERROR\|E_RECOVERABLE_ERROR\|E_ERROR\|E_CORE_ERROR"
ENV PHP_CGI_FIX_PATHINFO 0
RUN sed -i "s|;listen.owner\s*=\s*nobody|listen.owner = ${PHP_FPM_USER}|g" /etc/php7/php-fpm.d/www.conf && \
    sed -i "s|;listen.group\s*=\s*nobody|listen.group = ${PHP_FPM_GROUP}|g" /etc/php7/php-fpm.d/www.conf && \
    sed -i "s|;listen.mode\s*=\s*0660|listen.mode = ${PHP_FPM_LISTEN_MODE}|g" /etc/php7/php-fpm.d/www.conf && \
    sed -i "s|user\s*=\s*nobody|user = ${PHP_FPM_USER}|g" /etc/php7/php-fpm.d/www.conf && \
    sed -i "s|group\s*=\s*nobody|group = ${PHP_FPM_GROUP}|g" /etc/php7/php-fpm.d/www.conf && \
    sed -i "s|;log_level\s*=\s*notice|log_level = notice|g" /etc/php7/php-fpm.d/www.conf #uncommenting line && \
    sed -i "s|display_errors\s*=\s*Off|display_errors = ${PHP_DISPLAY_ERRORS}|i" /etc/php7/php.ini && \
    sed -i "s|display_startup_errors\s*=\s*Off|display_startup_errors = ${PHP_DISPLAY_STARTUP_ERRORS}|i" /etc/php7/php.ini && \
    sed -i "s|error_reporting\s*=\s*E_ALL & ~E_DEPRECATED & ~E_STRICT|error_reporting = ${PHP_ERROR_REPORTING}|i" /etc/php7/php.ini && \
    sed -i "s|;*memory_limit =.*|memory_limit = ${PHP_MEMORY_LIMIT}|i" /etc/php7/php.ini && \
    sed -i "s|;*upload_max_filesize =.*|upload_max_filesize = ${PHP_MAX_UPLOAD}|i" /etc/php7/php.ini && \
    sed -i "s|;*max_file_uploads =.*|max_file_uploads = ${PHP_MAX_FILE_UPLOAD}|i" /etc/php7/php.ini && \
    sed -i "s|;*post_max_size =.*|post_max_size = ${PHP_MAX_POST}|i" /etc/php7/php.ini && \
    sed -i "s|;*cgi.fix_pathinfo=.*|cgi.fix_pathinfo= ${PHP_CGI_FIX_PATHINFO}|i" /etc/php7/php.ini

# Copy files
COPY ./defaults/settings.json /defaults/settings.json
COPY ./defaults/nginx.conf /etc/nginx/nginx.conf
COPY --chown=www:www ./defaults/torr.php /www/torr/torr.php
COPY ./defaults/h2.mv.db /defaults/h2.mv.db
COPY ./defaults/run.sh /run.sh

# Initial script
RUN chown root:root /run.sh && \
    chmod 0555 /run.sh

# Ports and Volumes
EXPOSE 8080
VOLUME /root/data /download

# Run
ENTRYPOINT /run.sh
