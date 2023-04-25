<p align="center">
  <img width="750" alt="XXL-JOB" height="400" src="https://camo.githubusercontent.com/63881e271f889d4a424c55cea2f9c2065f63494fecac58432eac415f6e47e959/68747470733a2f2f696d672d626c6f672e6373646e696d672e636e2f32303139313130343130313733353934372e706e67">
</p>

# 1. prepare mysql
### i). my.cnf configuration
```inf
[mysqld]
log-bin=mysql-bin    # 开启 binlog
binlog-format=ROW    # 选择 ROW 模式
server_id=1          # 配置 MySQL replaction 需要定义，不要和 canal 的 slaveId 重复
```

### ii). grant `canal-db-user` permission
```inf
CREATE USER canal@'localhost' IDENTIFIED [WITH mysql_native_password] BY 'canal';  
GRANT SELECT, REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'canal'@'%';
-- GRANT ALL PRIVILEGES ON *.* TO 'canal'@'%' ;
```

# 2. create container image
Run `build.sh` script build container image.

they will download specified release `.tar.gz` package,

then will build container in localhost.

# 3. run this container
```shell
$ docker run -d --name=canal-server --restart=on-failure:3 \
    -e canal_user=canal \
    -e canal_passwd=<canal_db_user_password> \
    -e canal_tsdb=canal_tsdb \
    -e mysql=127.0.0.1 \
    -p 11110:11110 \
    -p 11111:11111 \
    -p 11112:11112 \
    canal-server:<tag>
```

# 4. get `/metrics` url
```shell
$ curl http://localhost:11112/metrics
```

# 5. application use ..
Maven pom.xml dependency:
```pom.xml
<dependency>
    <groupId>com.alibaba.otter</groupId>
    <artifactId>canal.client</artifactId>
    <version>1.1.4</version>
</dependency>
```

`canal-client` use tcp port `11111` to connect `canal-server`.

docs here → [https://github.com/alibaba/canal/wiki/ClientExample](https://github.com/alibaba/canal/wiki/ClientExample) ←