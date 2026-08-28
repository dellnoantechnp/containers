# OpenTelemetry Java Contrib Samplers Extension

This image provides the [OpenTelemetry Java Contrib Samplers](https://github.com/open-telemetry/opentelemetry-java-contrib/tree/main/samplers), which offers custom sampler implementations for OpenTelemetry Java instrumentation. The extension bridges profiling data with distributed traces, allowing you to correlate performance issues with specific lines of code.

## Docker Compose deployment

To use this image, mount the extension JAR into your application container and set the `OTEL_JAVAAGENT_EXTENSIONS` environment variable to load it.

```yaml
services:
  init-otel-samplers-extension:
    image: docker.io/dellnoantechnp/opentelemetry-java-contrib-samplers-extension:latest
    volumes:
      - shared-data:/opentelemetry-samplers
    command: >
      sh -c "echo 'Start copying files.' &&
             cp /opentelemetry-java-contrib/opentelemetry-samplers.jar /opentelemetry-samplers/opentelemetry-samplers.jar &&
             echo 'Copy completed!'"

  my-java-app:
    ports:
      - "5000"
    environment:
      OTLP_URL: tempo:4318
      OTLP_INSECURE: 1
      OTEL_TRACES_EXPORTER: otlp
      OTEL_EXPORTER_OTLP_ENDPOINT: http://tempo:4317
      OTEL_EXPORTER_OTLP_PROTOCOL: grpc
      OTEL_SERVICE_NAME: rideshare.java.push.app
      OTEL_METRICS_EXPORTER: none
      OTEL_TRACES_SAMPLER: always_on
      OTEL_PROPAGATORS: tracecontext
      PYROSCOPE_SERVER_ADDRESS: http://pyroscope:4040
      REGION: eu-north
      OTEL_JAVAAGENT_EXTENSIONS: /opentelemetry-samplers/opentelemetry-samplers.jar
    # mount shared volumes
    volumes:
      - shared-data:/opentelemetry-samplers
    command: >
      sh -c "java -Dserver.port=5000 -javaagent:./opentelemetry-javaagent.jar -jar /my-java-app.jar"

    depends_on:
      init-otel-samplers-extension:
        condition: service_completed_successfully

volumes:
  shared-data:
```

## Kubernetes deployment

In Kubernetes, use an init container to copy the extension JAR into a shared volume, then mount that volume in the application container and set `OTEL_JAVAAGENT_EXTENSIONS`.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  labels:
    app: my-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
      annotations:
        # opentelemetry-autoinstrumentation
        instrumentation.opentelemetry.io/inject-java: "true"
    spec:
      containers:
        - image: registry.example.com/java-backend/my-app:latest
          name: my-app
          env:
            - name: app
              valueFrom:
                fieldRef:
                  apiVersion: v1
                  fieldPath: metadata.labels['app']
            - name: POD_NAME
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
            - name: POD_NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
            - name: PYROSCOPE_APPLICATION_NAME
              value: $(app)
            - name: PYROSCOPE_SERVER_ADDRESS
              value: http://pyroscope-distributor.infrastructure.svc:4040
            - name: PYROSCOPE_LABELS
              value: "pod=$(POD_NAME),namespace=$(POD_NAMESPACE)"

            - name: PYROSCOPE_PROFILER_ALLOC
              value: "512k"

            - name: PYROSCOPE_ALLOC_LIVE
              value: "true"

            - name: PYROSCOPE_PROFILER_LOCK
              value: "10ms"

            - name: OTEL_JAVAAGENT_EXTENSIONS
              value: /opentelemetry-samplers/opentelemetry-samplers.jar
          ports:
            - containerPort: 5000
              protocol: TCP
              name: http-5000
          volumeMounts:
            - mountPath: /opentelemetry-samplers
              name: otel-samplers-extension
      initContainers:
        - image: docker.io/dellnoantechnp/opentelemetry-java-contrib-samplers-extension:v1.43.0
          name: otel-samplers-extension
          command:
            - sh
            - "-c"
          args:
            - >
              cp -a /opentelemetry-java-contrib/opentelemetry-samplers.jar /opentelemetry-samplers/opentelemetry-samplers.jar
          volumeMounts:
            - mountPath: /opentelemetry-samplers
              name: otel-samplers-extension
      volumes:
        - name: otel-samplers-extension
          emptyDir: {}
```

## Version Compatibility

`OTEL_JAVAAGENT_EXTENSIONS` is loaded as an extension of the OpenTelemetry javaagent, so the extension version must be compatible with the base OpenTelemetry Java Agent version. Version compatibility information is documented in the [OpenTelemetry Java Contrib releases](https://github.com/open-telemetry/opentelemetry-java-contrib/releases).

For example, Release `1.59.0` states: "This release targets the OpenTelemetry Java Instrumentation 2.30.0." This means the extension version `1.59.0` should be used with `opentelemetry-java-instrumentation` version `2.30.0`.

| Extension Version | Targets OpenTelemetry Java Instrumentation |
|-------------------|--------------------------------------------|
| 1.59.0            | 2.30.0                                     |
| 1.58.0            | 2.29.0                                     |
| 1.57.0            | 2.28.0                                     |