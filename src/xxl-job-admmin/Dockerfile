FROM openjdk:11-slim-bullseye
LABEL org.opencontainers.image.source=https://github.com/dellnoantechnp/containers \
      org.opencontainers.image.description="xuxueli/xxl-job xxl-job-admin container image." \
      org.opencontainers.image.created="2023-06-09T07:20:00Z" \
      org.opencontainers.image.title="xxl-job-admin" \
      org.opencontainers.image.version="2.4.0"


WORKDIR /app
ENV OS_ARCH="${TARGETARCH:-amd64}" \
    OS_FLAVOUR="debian-11" \
    OS_NAME="linux" \
    PATH="/opt/scripts:$PATH" \
    APP_NAME="xxl-job-admin" \
    WORKDIR="/app"

COPY prebuildfs /
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install required system packages and dependencies
RUN install_packages file procps curl netcat ca-certificates

COPY files .

EXPOSE 8080
ENTRYPOINT [ "/opt/scripts/entrypoint.sh" ]
CMD [ "./startup.sh", "start" ]