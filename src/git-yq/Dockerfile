FROM --platform=$TARGETPLATFORM bitnami/git:2.44.0-debian-12-r0
LABEL org.opencontainers.image.source=https://github.com/dellnoantechnp/containers \
      org.opencontainers.image.description="Devops tools container images." \
      org.opencontainers.image.created="2024-04-09T01:20:00Z" \
      org.opencontainers.image.title="git-yq" \
      org.opencontainers.image.version="2.44.0"


WORKDIR /
ENV OS_ARCH="${TARGETARCH:-amd64}" \
    OS_FLAVOUR="debian-12" \
    OS_NAME="${TARGETOS:-linux}"

COPY prebuildfs /
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install required system packages and dependencies
RUN install_packages file procps curl netcat-openbsd ca-certificates
RUN install_packages jq wget
RUN wget https://github.com/mikefarah/yq/releases/download/v4.43.1/yq_linux_${OS_ARCH} -O /usr/bin/yq &&\
    chmod +x /usr/bin/yq
