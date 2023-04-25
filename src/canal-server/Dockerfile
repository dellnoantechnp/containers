FROM openjdk:8u342-slim-bullseye
WORKDIR /app
ENV abs_bin_path=/app/canal-server/bin
ADD canal.deployer-1.1.6.tar.gz /app/canal-server
ADD files /app/files
RUN cp files/startup.sh canal-server/bin/startup.sh ;\
    cp files/logback.xml canal-server/conf/logback.xml ;\
    cp files/canal.properties canal-server/conf/canal.properties ;\
    cp files/instance.properties canal-server/conf/example/instance.properties
EXPOSE 11110 11111 11112
CMD ["./canal-server/bin/startup.sh"]