FROM tomcat:9.0.48-jdk11-openjdk-slim
COPY target/*.war /usr/local/tomcat/webapps/


