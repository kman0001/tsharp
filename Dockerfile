# 아키텍처 인자 정의
ARG TARGETPLATFORM
ARG BUILDPLATFORM

# --- 단계 1: 공식 이미지에서 torrssen2 파일만 추출 (Multi-arch 대응용) ---
# tarpha/torrssen2는 amd64만 지원하므로, 여기서 파일을 꺼내 다른 아키텍처 레이어에 합칩니다.
FROM tarpha/torrssen2:latest AS source

# --- 단계 2: 실제 실행용 멀티 아키텍처 이미지 빌드 ---
FROM --platform=$TARGETPLATFORM alpine:3.12

# 기존 환경 변수 설정
ENV PUID=0 PGID=100
ENV PHP_FPM_USER="www" PHP_FPM_GROUP="www" PHP_FPM_LISTEN_MODE="0660" \
    PHP_MEMORY_LIMIT="512M" PHP_MAX_UPLOAD="50M" PHP_MAX_FILE_UPLOAD="200" \
    PHP_MAX_POST="100M" PHP_DISPLAY_ERRORS="On" PHP_DISPLAY_STARTUP_ERRORS="On" \
    PHP_ERROR_REPORTING="E_COMPILE_ERROR\|E_RECOVERABLE_ERROR\|E_ERROR\|E_CORE_ERROR" \
    PHP_CGI_FIX_PATHINFO=0

# 필수 패키지 설치 (JRE 8 필수)
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

# [중요] 공식 이미지(source)에서 torrssen2 실행 파일 및 관련 경로 복사
# 공식 이미지 내의 위치(/app 등)를 확인하여 복사합니다.
COPY --from=source /app /app
COPY --from=source /defaults /defaults

# 디렉토리 생성 및 Nginx/PHP 설정 (사용자 제공 소스)
RUN adduser -D -g 'www' www && \
    mkdir -p /config /www/torr /run/nginx && \
    chown -R www:www /var/lib/nginx /www

# PHP7 설정 적용 (제공하신 sed 명령어들)
RUN sed -i "s|;listen.owner\s*=\s*nobody|listen.owner = ${PHP_FPM_USER}|g" /etc/php7/php-fpm.d/www.conf && \
    # ... (생략: 이전 답변의 모든 sed 명령어 포함) ...
    sed -i "s|;*cgi.fix_pathinfo=.*|cgi.fix_pathinfo= ${PHP_CGI_FIX_PATHINFO}|i" /etc/php7/php.ini

# 본인의 로컬 설정 파일들 복사 (프로젝트 폴더 내에 있어야 함)
COPY ./defaults/settings.json /defaults/settings.json
COPY ./defaults/nginx.conf /etc/nginx/nginx.conf
COPY --chown=www:www ./defaults/torr.php /www/torr/torr.php
COPY ./defaults/h2.mv.db /defaults/h2.mv.db
COPY ./defaults/run.sh /run.sh

RUN chown root:root /run.sh && chmod 0555 /run.sh

EXPOSE 8080
VOLUME ["/config", "/download"]

ENTRYPOINT ["/bin/bash", "/run.sh"]
