FROM openjdk:11-slim-bullseye
LABEL org.opencontainers.image.source=https://github.com/dellnoantechnp/containers \
      org.opencontainers.image.description="Alibaba canal-server container images." \
      org.opencontainers.image.created="2023-04-27T06:20:00Z" \
      org.opencontainers.image.title="canal-server" \
      org.opencontainers.image.version="1.1.6"


WORKDIR /app
ENV OS_ARCH="${TARGETARCH:-amd64}" \
    OS_FLAVOUR="debian-11" \
    OS_NAME="linux" \
    abs_bin_path=/app/canal-server/bin \
    PATH="/opt/scripts:$PATH" \
    APP_NAME="Canal-Server"

COPY prebuildfs /
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install required system packages and dependencies
RUN install_packages file procps curl netcat ca-certificates

ADD canal.deployer.tar.gz /app/canal-server
COPY files /app/files
RUN cp files/startup.sh canal-server/bin/startup.sh ;\
    cp files/logback.xml canal-server/conf/logback.xml ;\
    cp files/canal.properties canal-server/conf/canal.properties
#    ;\
#    cp files/instance.properties canal-server/conf/example/instance.properties
EXPOSE 11110 11111 11112
ENTRYPOINT [ "/opt/scripts/entrypoint.sh" ]
CMD [ "./canal-server/bin/startup.sh" ]