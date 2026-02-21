# 1단계: 기존 amd64 전용 이미지에서 파일만 추출하기 위해 임시로 불러옴
FROM tarpha/torrssen2:latest AS source

# 2단계: 실제 우리가 사용할 멀티 아키텍처(AMD64/ARM64) 기반 이미지 빌드
FROM alpine:3.12

# 환경 변수 및 패키지 설정 (기존 소스 유지)
ENV PUID=0 PGID=100
ENV PHP_FPM_USER="www" PHP_FPM_GROUP="www" PHP_FPM_LISTEN_MODE="0660" \
    PHP_MEMORY_LIMIT="512M" PHP_MAX_UPLOAD="50M" PHP_MAX_FILE_UPLOAD="200" \
    PHP_MAX_POST="100M" PHP_DISPLAY_ERRORS="On" PHP_DISPLAY_STARTUP_ERRORS="On" \
    PHP_ERROR_REPORTING="E_COMPILE_ERROR\|E_RECOVERABLE_ERROR\|E_ERROR\|E_CORE_ERROR" \
    PHP_CGI_FIX_PATHINFO=0

# 자바(JRE8) 및 필수 패키지 설치
RUN apk update && \
    apk add --no-cache \
    openjdk8-jre \
    transmission-daemon \
    nginx \
    php7 \
    php7-fpm \
    php7-openssl \
    php7-curl \
    bash \
    curl \
    sed

# [핵심] 기존 이미지(source)의 루트(/)에 있던 jar 파일을 새 이미지의 루트(/)로 복사
COPY --from=source /torrssen2.jar /torrssen2.jar

# 디렉토리 생성 및 권한 설정
RUN adduser -D -g 'www' www && \
    mkdir -p /config /www/torr /run/nginx /defaults && \
    chown -R www:www /var/lib/nginx /www

# PHP7 설정 적용 (제공해주신 sed 스크립트들)
RUN sed -i "s|;listen.owner\s*=\s*nobody|listen.owner = ${PHP_FPM_USER}|g" /etc/php7/php-fpm.d/www.conf && \
    # ... (중략: 기존의 모든 sed 명령어들 그대로 유지) ...
    sed -i "s|;*cgi.fix_pathinfo=.*|cgi.fix_pathinfo= ${PHP_CGI_FIX_PATHINFO}|i" /etc/php7/php.ini

# 로컬 설정 파일들 복사
COPY ./defaults/settings.json /defaults/settings.json
COPY ./defaults/nginx.conf /etc/nginx/nginx.conf
COPY --chown=www:www ./defaults/torr.php /www/torr/torr.php
COPY ./defaults/h2.mv.db /defaults/h2.mv.db
COPY ./defaults/run.sh /run.sh

RUN chown root:root /run.sh && chmod 0555 /run.sh

EXPOSE 8080
VOLUME ["/config", "/download"]

# 실행 (기존 run.sh가 /torrssen2.jar를 실행하도록 작성되어 있어야 함)
ENTRYPOINT ["/bin/bash", "/run.sh"]
