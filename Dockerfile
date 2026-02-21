# 빌드 인자 정의
ARG TARGETPLATFORM
ARG BUILDPLATFORM

# 베이스 이미지 (멀티 아키텍처 지원되는 Alpine 사용)
FROM --platform=$TARGETPLATFORM alpine:3.12

ENV PUID 0
ENV PGID 100

# 패키지 설치 (PHP7은 Alpine 3.12 버전에서 안정적입니다)
RUN apk update && \
    apk add --no-cache \
    transmission-daemon \
    nginx \
    php7 \
    php7-fpm \
    php7-openssl \
    php7-curl \
    bash \
    curl

# Torrssen2 바이너리 및 설정 (공식 빌드 방식 참고)
# 실제 빌드 시에는 해당 프로젝트의 jar 파일 등이 필요할 수 있습니다.
RUN mkdir -p /config /www/torr /run/nginx

# Nginx 및 PHP 설정 (기존 소스 유지)
RUN adduser -D -g 'www' www && \
    chown -R www:www /var/lib/nginx /www

# ... (기존 PHP 환경변수 및 sed 명령어들 유지) ...
ENV PHP_FPM_USER "www"
# [중략: 기존에 제공해주신 PHP 설정 내용을 여기에 그대로 넣으시면 됩니다]

# 파일 복사
COPY ./defaults/settings.json /defaults/settings.json
COPY ./defaults/nginx.conf /etc/nginx/nginx.conf
COPY --chown=www:www ./defaults/torr.php /www/torr/torr.php
COPY ./defaults/h2.mv.db /defaults/h2.mv.db
COPY ./defaults/run.sh /run.sh

RUN chmod 0555 /run.sh

EXPOSE 8080
VOLUME /root/data /download

ENTRYPOINT ["/run.sh"]
