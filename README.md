# urotaxi
To launch the urotaxi application we need to pass the below properties as environment varaibles pointing to the database server details
spring.datasource.url=jdbc:mysql://<dbhost>:<dbport>/urotaxidb
spring.datasource.username=<dbusername>
spring.datasource.password=<dbpassword>

docker network create urotaxinetwork
docker volume create urotaxidbvol

# build the project
mvn clean verify 

# launch the mysql server docker container
docker container run --name urotaximysqldb --network urotaxinetwork --mount type=volume,source=urotaxidbvol,target=/var/lib/mysql -e MYSQL_ROOT_PASSWORD=welcome1 -d mysql:8.0.28

#  create db schema on the mysql server instance
docker cp src/main/db/urotaxidb.sql urotaximysqldb:/
docker container exec -it urotaximysqldb bash

# verify in docker container whether urotaxidb has been created or not
mysql -uroot -pwelcome1
show databases;
use urotaxidb;
show tables;
exit;

# build the docker image
docker image build -t jcrhub.com/docker/urotaxi:1.0 .

# run the docker container
open variables.env and populate database information appropriately
docker container run --name urotaxi --network=urotaxinetwork -p 8080:8082 --env-file=variables.env -d jcrhub.com/docker/urotaxi:1.0


#MyNotes
# 1.Modify the urotaxi web application to work with docker
a.Modify the src/main/resources/application.yml as tomcat does not accept the vars.env
   url: jdbc:mysql://urotaximysqldb/urotaxidb
   username: root
   password: root



b.Update the pom.xml with below entry
   <name>urotaxi</name>
   <packaging>war</packaging>


# 2.Build the war using maven, go to urotaxi folder and run below command
   mvn clean verify


# 3.Create the docker network
docker network create urotaxinetwork
docker volume create urotaxidbvol


# 4.Build the container from the image available from the docker hub
docker container run --name urotaximysqldb --network urotaxinw --mount type=volume,source=urotaxidbvol,target=/var/lib/mysql -e MYSQL_ROOT_PASSWORD=welcome1 -d mysql:8.0.28   
docker container ls [Should see mysql db container]


# 5 Create db schema on the mysql server instance
a.Copying the file from host to docker container
docker cp urotaxi/src/main/db/urotaxidb.sql urotaximysqldb:/tmp


b.Login into the mysql docker container
docker container exec -it urotaximysqldb /bin/bash


c.create the schema by running the urotaxidb.sql
mysql>mysql -uroot -pwelcome1 < /tmp/urotaxidb.sql


# 6 verify in docker container whether urotaxidb has been created or not
mysql -uroot -pwelcome1
show databases;
use urotaxidb;
show tables;
exit;


# 7 Write the Dockerfile to install Java[from local repo], tomcat from internet, copy war into Docker
----------------------------------------------------------------
FROM ubuntu:23.04
#ENV JAVA_HOME=/u01/middleware/openjdk-11.0.2
ENV JAVA_HOME=/u01/middleware/jdk-11.0.2
ENV TOMCAT_HOME=/u01/middleware/apache-tomcat-9.0.71
ENV PATH=${PATH}:${JAVA_HOME}/bin:${TOMCAT_HOME}/bin


RUN mkdir -p /u01/middleware/


WORKDIR /u01/middleware/
#ADD https://download.java.net/java/GA/jdk11/9/GPL/openjdk-11.0.2_linux-x64_bin.tar.gz . 
COPY openjdk-11.0.2_linux-x64_bin.tar.gz .    
RUN tar -xvzf openjdk-11.0.2_linux-x64_bin.tar.gz
RUN rm openjdk-11.0.2_linux-x64_bin.tar.gz


ADD https://dlcdn.apache.org/tomcat/tomcat-9/v9.0.71/bin/apache-tomcat-9.0.71.tar.gz . 
RUN tar -xvzf apache-tomcat-9.0.71.tar.gz
RUN rm apache-tomcat-9.0.71.tar.gz


RUN apt update -y
RUN apt install -y curl


WORKDIR ${TOMCAT_HOME}/webapps/


#COPY /urotaxi/target/urotaxi-1.0.war .
COPY /urotaxi/target/urotaxi.war .
COPY run.sh /tmp
RUN chmod u+x ${TOMCAT_HOME}/bin/startup.sh
RUN chmod u+x /tmp/run.sh




ENTRYPOINT ["/tmp/run.sh"]
#CMD ["tail -f /dev/null"]


HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 CMD curl -f http://localhost:8080/urotaxi/actuator/health || exit 1
----------------------------------------------------------------


# 7.Build the docker image & run the urotaxi docker container
docker image build -t urotaxi:1.0 .
docker container run -d --name urotaxi -p8080:8080 --env-file=vars.env --network urotaxinw urotaxi:1.0
docker container ls
docker container logs upbeat_chatterjee


To check the tomcat catalina.out logs
a)Login into the urotaxi container
   docker container exec -it upbeat_chatterjee /bin/bash


b)cat tomcat/logs/catalina.out


# 8 When you list the docker containers you should see urotaxi contaner as healthy
IMAGE        STATUS                      PORTS                                      NAMES
urotaxi:1.0  Up About an hour (healthy)  0.0.0.0:8080->8080/tcp, :::8080->8080/tcp   urotaxi




# 9 Open browser and access urotaxi web application
http://localhost:8080/urotaxi/index.html


# 10 Once you book any ride, it can be seen the mysql database
mysql> select * from ride;
+---------+----------+-------------+------------+-------------+
| ride_no | car_type | destination | mobile_no  | source      |
+---------+----------+-------------+------------+-------------+
|       7 | Sedan    | Calvary     | 9700543741 | Dilsuknagar |
+---------+----------+-------------+------------+-------------+

