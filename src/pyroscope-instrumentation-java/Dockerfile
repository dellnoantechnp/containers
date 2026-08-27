# To build one pyroscope-instrumentation-java auto-instrumentation image for Java, please:
#  - Download your customized `pyroscope.jar` to `/javaagent.jar`. This is required as when instrumenting the pod,
#    one init container will be created to copy the jar to your app's container.
#  - Grant the necessary access to the jar. `chmod -R go+r /javaagent.jar`
#  - For auto-instrumentation by container injection, the Linux command cp is
#    used and must be available in the image.
FROM busybox@sha256:fd8d9aa63ba2f0982b5304e1ee8d3b90a210bc1ffb5314d980eb6962f1a9715d

ARG version
ARG BUILD_DATE
ARG BUILD_AUTHOR
ARG BUILD_IMAGE_URL

LABEL org.opencontainers.image.created="$BUILD_DATE" \
      org.opencontainers.image.authors="$BUILD_AUTHOR" \
      org.opencontainers.image.url="$BUILD_IMAGE_URL" \
      org.opencontainers.image.version="v$version" \
      org.opencontainers.image.title="Pyroscope Instrumentation Java" \
      org.opencontainers.image.description="The Java profiling agent for Pyroscope.io. Based on async-profiler."


ADD https://github.com/grafana/pyroscope-java/releases/download/$version/pyroscope.jar /javaagent.jar

RUN chmod -R go+r /javaagent.jar
