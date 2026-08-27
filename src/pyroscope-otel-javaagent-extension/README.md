# Pyroscope OpenTelemetry Java Agent Extension

This image provides the [Pyroscope OpenTelemetry Java Agent Extension](https://github.com/grafana/pyroscope/tree/main/examples/tracing/java), which enables auto-instrumentation for Java applications using OpenTelemetry. The extension bridges profiling data with distributed traces, allowing you to correlate performance issues with specific lines of code.

## Docker Compose deployment

To use this image, mount the extension JAR into your application container and set the `OTEL_JAVAAGENT_EXTENSIONS` environment variable to load it.

```yaml
services:
  init-pyroscope-javaagent-extension:
    image: docker.io/dellnoantechnp/pyroscope-otel-javaagent-extension:latest
    volumes:
      - shared-data:/pyroscope-otel-extension
    command: >
      sh -c "echo 'Start copying files.' &&
             cp /pyroscope-otel-javaagent-extension/pyroscope-otel-javaagent-extension.jar /pyroscope-otel-extension/pyroscope-otel-javaagent-extension.jar &&
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
      OTEL_JAVAAGENT_EXTENSIONS: /pyroscope-otel-extension/pyroscope-otel-javaagent-extension.jar
    # mount shared volumes
    volumes:
      - shared-data:/pyroscope-otel-extension
    command: >
      sh -c "java -Dserver.port=5000 -javaagent:./opentelemetry-javaagent.jar -jar /my-java-app.jar"

    depends_on:
      init-pyroscope-javaagent-extension:
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
              value: /pyroscope-otel-extension/pyroscope-otel-javaagent-extension.jar
          ports:
            - containerPort: 5000
              protocol: TCP
              name: http-5000
          volumeMounts:
            - name: pyroscope-extension
              mountPath: /pyroscope-otel-extension
      initContainers:
        - image: docker.io/dellnoantechnp/pyroscope-otel-javaagent-extension:v2.1.0
          name: pyroscope-extension
          command:
            - sh
            - "-c"
          args:
            - >
              cp -a /pyroscope-otel-javaagent-extension/pyroscope-otel-javaagent-extension.jar /pyroscope-otel-extension/pyroscope-otel-javaagent-extension.jar
          volumeMounts:
            - mountPath: /pyroscope-otel-extension
              name: pyroscope-extension
      volumes:
        - name: pyroscope-extension
          emptyDir: {}
```