# 1단계: 원본 이미지에서 파일 추출
FROM tarpha/torrssen2:latest AS source

# 2단계: 실제 실행용 멀티 아키텍처 이미지 (Alpine 3.12)
FROM alpine:3.12

# 환경 변수 설정
ENV PUID=0 PGID=100

# 필수 패키지 설치 (git은 run.sh의 git pull 에러 방지용)
RUN apk update && apk add --no-cache \
    openjdk8-jre \
    transmission-daemon \
    nginx \
    php7 \
    php7-fpm \
    php7-openssl \
    php7-curl \
    bash \
    curl \
    sed \
    git

# 1. [핵심] run.sh가 찾는 경로 강제로 만들기
# run.sh 46행: cd /torrssen2 && git pull
# run.sh 48행: cp /torrssen2/docker/torrssen2-*.jar torrssen2.jar
RUN mkdir -p /torrssen2/docker && \
    cd /torrssen2 && git init && \
    git config user.email "you@example.com" && \
    git config user.name "Your Name" && \
    git commit --allow-empty -m "init"

# 2. 원본 jar 파일을 복사될 위치에 미리 넣어둠
COPY --from=source /torrssen2.jar /torrssen2/docker/torrssen2-current.jar

# 3. [핵심] Java 옵션 에러 해결 (Wrapper 스크립트)
# OpenJDK에서 인식 못하는 -Xshareclasses 등을 실행 직전에 가로채서 삭제함
RUN mv /usr/bin/java /usr/bin/java-original && \
    echo '#!/bin/bash' > /usr/bin/java && \
    echo 'exec /usr/bin/java-original "${@//-Xshareclasses/}" "${@//-Xquickstart/}"' >> /usr/bin/java && \
    chmod +x /usr/bin/java

# 4. 나머지 기존 설정 (사용자 추가, PHP 설정 등)
RUN adduser -D -g 'www' www && \
    mkdir -p /config /www/torr /run/nginx /defaults && \
    chown -R www:www /var/lib/nginx /www

# [제공해주신 PHP sed 명령어들 삽입 위치]
# RUN sed -i ... (기존 설정 그대로 사용)

# 설정 파일 복사
COPY ./defaults/settings.json /defaults/settings.json
COPY ./defaults/nginx.conf /etc/nginx/nginx.conf
COPY --chown=www:www ./defaults/torr.php /www/torr/torr.php
COPY ./defaults/h2.mv.db /defaults/h2.mv.db
COPY ./defaults/run.sh /run.sh

RUN chmod 0555 /run.sh

EXPOSE 8080
VOLUME ["/root/data", "/download"]

ENTRYPOINT ["/bin/bash", "/run.sh"]
