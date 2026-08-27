# Pyroscope Instrumentation Java

This image provides the [Pyroscope Java profiling agent](https://github.com/grafana/pyroscope-java), which enables auto-instrumentation for Java applications. It packages `pyroscope.jar` (based on async-profiler) to capture CPU profiles and send them to Pyroscope.

## Docker Compose deployment

To use this image, mount the agent JAR into your application container via a shared volume, then set the `-javaagent` JVM argument and relevant Pyroscope environment variables.

```yaml
services:
  init-pyroscope-javaagent:
    image: docker.io/dellnoantechnp/pyroscope-instrumentation-java:latest
    volumes:
      - shared-data:/pyroscope
    command: >
      sh -c "echo 'Copying jar.' &&
             cp /javaagent.jar /pyroscope/javaagent.jar &&
             echo 'Copy completed!'"

  my-java-app:
    ports:
      - "5000"
    environment:
      PYROSCOPE_SERVER_ADDRESS: http://pyroscope:4040
      PYROSCOPE_APPLICATION_NAME: my-java-app
      PYROSCOPE_PROFILER_ALLOC: 512k
      PYROSCOPE_ALLOC_LIVE: "true"
      PYROSCOPE_PROFILER_LOCK: 10ms
    # mount shared volumes
    volumes:
      - shared-data:/pyroscope
    command: >
      sh -c "java -Dserver.port=5000 -javaagent:/pyroscope/javaagent.jar -jar /my-java-app.jar"

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
          command:
            - sh
            - "-c"
          args:
            - >
              java -javaagent:/pyroscope/javaagent.jar -jar my-app.jar
          ports:
            - containerPort: 5000
              protocol: TCP
              name: http-5000
          volumeMounts:
            - name: pyroscope
              mountPath: /pyroscope
      initContainers:
        - image: docker.io/dellnoantechnp/pyroscope-instrumentation-java:v2.8.0
          name: pyroscope-instrumentation-java
          command:
            - sh
            - "-c"
          args:
            - >
              cp -a /javaagent.jar /pyroscope/javaagent.jar
          volumeMounts:
            - mountPath: /pyroscope
              name: pyroscope
      volumes:
        - name: pyroscope
          emptyDir: {}
```
