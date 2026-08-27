# To build one pyroscope-otel-javaagent-extension auto-instrumentation image for Java, please:
#  - Download your customized `pyroscope-otel-javaagent-extension.jar` to
# `/pyroscope-otel-javaagent-extension/pyroscope-otel-javaagent-extension.jar`.
# This is required as when instrumenting the pod,
#    one init container will be created to copy the jar to your app's container.
#  - Grant the necessary access to the jar. `chmod -R go+r /pyroscope-otel-javaagent-extension.jar`
#  - For auto-instrumentation by container injection, the Linux command cp is
#    used and must be available in the image.
FROM busybox@sha256:fd8d9aa63ba2f0982b5304e1ee8d3b90a210bc1ffb5314d980eb6962f1a9715d

ARG version
ARG BUILD_DATE
ARG BUILD_AUTHOR
ARG BUILD_IMAGE_URL

LABEL org.opencontainers.image.title="otel profling integration for java" \
      org.opencontainers.image.description="Pyroscope can integrate with distributed tracing systems supporting OpenTelemetry standard which allows you to link traces with the profiling data, and find specific lines of code related to a performance issue." \
      org.opencontainers.image.url="$BUILD_IMAGE_URL" \
      org.opencontainers.image.authors="$BUILD_AUTHOR" \
      org.opencontainers.image.version="v$version" \
      org.opencontainers.image.created="$BUILD_DATE"

ADD https://github.com/grafana/otel-profiling-java/releases/download/v$version/pyroscope-otel-javaagent-extension.jar \
  /pyroscope-otel-javaagent-extension/pyroscope-otel-javaagent-extension.jar

RUN chmod go+r /pyroscope-otel-javaagent-extension/pyroscope-otel-javaagent-extension.jar
