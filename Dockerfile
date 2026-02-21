# 1. 원본에서 파일만 추출
ARG TARGETPLATFORM
FROM --platform=linux/amd64 tarpha/torrssen2:latest AS source

FROM --platform=$TARGETPLATFORM alpine:3.12

# 2. 멀티 아키텍처 지원 베이스 이미지 (Alpine 3.12)
FROM alpine:3.12

# 환경 변수 설정
ENV PUID=0 PGID=100

# [Transmission 설치] - 여기서 각 아키텍처에 맞는 바이너리가 자동으로 깔립니다.
RUN apk update && apk add --no-cache \
    transmission-daemon \
    openjdk8-jre nginx php7 php7-fpm php7-openssl php7-curl bash curl sed git

# [Transmission 설정] - 기존에 작성하신 경로 설정을 그대로 유지합니다.
RUN mkdir -p /config /download /root/data && \
    chmod 0755 /config /download /root/data

# [기존 Nginx/PHP 설정]
RUN adduser -D -g 'www' www && \
    mkdir -p /www/torr /run/nginx && \
    chown -R www:www /var/lib/nginx /www

# 원본에서 추출한 jar 파일 배치
COPY --from=source /torrssen2.jar /torrssen2.jar

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

# 설정 파일 및 실행 스크립트 복사
COPY ./defaults/settings.json /defaults/settings.json
COPY ./defaults/nginx.conf /etc/nginx/nginx.conf
COPY --chown=www:www ./defaults/torr.php /www/torr/torr.php
COPY ./defaults/h2.mv.db /defaults/h2.mv.db
COPY ./defaults/run.sh /run.sh

# [중요] ARM/AMD64 공용 호환을 위해 run.sh 자동 패치
RUN sed -i 's/-Xshareclasses -Xquickstart//g' /run.sh && \
    sed -i 's|/torrssen2/docker/torrssen2-\*.jar|/torrssen2.jar|g' /run.sh && \
    chmod 0555 /run.sh

EXPOSE 8080
VOLUME ["/config", "/download", "/root/data"]

ENTRYPOINT ["/bin/bash", "/run.sh"]


