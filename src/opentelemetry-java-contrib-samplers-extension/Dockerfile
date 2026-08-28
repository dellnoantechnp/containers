# To build one otel-java-contrib-samplers-extension image, please:
#  - Download your customized `opentelemetry-samplers.jar` to
# `/opentelemetry-samplers/opentelemetry-samplers.jar`.
# This is required as when instrumenting the pod,
#    one init container will be created to copy the jar to your app's container.
#  - Grant the necessary access to the jar. `chmod -R go+r /opentelemetry-samplers/opentelemetry-samplers.jar`
#  - For auto-instrumentation by container injection, the Linux command cp is
#    used and must be available in the image.
FROM busybox@sha256:fd8d9aa63ba2f0982b5304e1ee8d3b90a210bc1ffb5314d980eb6962f1a9715d

ARG version
ARG BUILD_DATE
ARG BUILD_AUTHOR
ARG BUILD_IMAGE_URL

LABEL org.opencontainers.image.title="opentelemetry samplers extension for java" \
      org.opencontainers.image.description="OpenTelemetry Java Contrib Samplers - provides custom sampler implementations for OpenTelemetry Java instrumentation." \
      org.opencontainers.image.url="$BUILD_IMAGE_URL" \
      org.opencontainers.image.authors="$BUILD_AUTHOR" \
      org.opencontainers.image.version="v$version" \
      org.opencontainers.image.created="$BUILD_DATE"

ADD https://repo1.maven.org/maven2/io/opentelemetry/contrib/opentelemetry-samplers/$version/opentelemetry-samplers-$version.jar \
  /opentelemetry-java-contrib/opentelemetry-samplers.jar

RUN chmod go+r /opentelemetry-java-contrib/opentelemetry-samplers.jar
