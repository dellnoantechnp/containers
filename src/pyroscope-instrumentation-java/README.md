# Pyroscope Instrumentation Java

This image provides the [Pyroscope Java profiling agent](https://github.com/grafana/pyroscope-java), which enables auto-instrumentation for Java applications. It packages `pyroscope.jar` (based on async-profiler) to capture CPU profiles and send them to Pyroscope.

## Docker Compose deployment

To use this image, mount the agent JAR into your application container via a shared volume, then set the `-javaagent` JVM argument and relevant Pyroscope environment variables.

```yaml
services:
  init-pyroscope-javaagent:
    image: docker.io/dellnoantechnp/pyroscope-instrumentation-java:latest
    volumes:
      - shared-data:/pyroscope-otel-extension
    command: >
      sh -c "cp /javaagent.jar /pyroscope-otel-extension/javaagent.jar"

  my-java-app:
    ports:
      - "5000:5000"
    environment:
      PYROSCOPE_SERVER_ADDRESS: http://pyroscope:4040
      OTEL_JAVAAGENT_EXTENSIONS: /pyroscope-otel-extension/javaagent.jar
    volumes:
      - shared-data:/pyroscope-otel-extension
    command: >
      sh -c "java -Dserver.port=5000 -javaagent:/pyroscope-otel-extension/javaagent.jar -jar /my-java-app.jar"
    depends_on:
      init-pyroscope-javaagent:
        condition: service_completed_successfully

volumes:
  shared-data:
```

## Kubernetes deployment

In Kubernetes, use an init container to copy the agent JAR into a shared volume, then mount that volume in the application container and add `-javaagent` to the JVM arguments.

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
    spec:
      containers:
        - image: registry.example.com/java-backend/my-app:latest
          name: my-app
          env:
            - name: PYROSCOPE_SERVER_ADDRESS
              value: http://pyroscope-distributor.infrastructure.svc:4040
            - name: PYROSCOPE_APPLICATION_NAME
              valueFrom:
                fieldRef:
                  apiVersion: v1
                  fieldPath: metadata.labels['app']
          ports:
            - containerPort: 5000
              protocol: TCP
              name: http-5000
          volumeMounts:
            - name: pyroscope-agent
              mountPath: /pyroscope-otel-extension
          args:
            - "-javaagent:/pyroscope-otel-extension/javaagent.jar"
      initContainers:
        - image: docker.io/dellnoantechnp/pyroscope-instrumentation-java:latest
          name: init-pyroscope-agent
          command:
            - sh
            - "-c"
          args:
            - cp -a /javaagent.jar /pyroscope-otel-extension/javaagent.jar
          volumeMounts:
            - mountPath: /pyroscope-otel-extension
              name: pyroscope-agent
      volumes:
        - name: pyroscope-agent
          emptyDir: {}
```
