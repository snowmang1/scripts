#!/bin/bash
yum update -y

# Tomcatv7
yum install -y tomcat maven wget git
systemctl start tomcat
systemctl enable tomcat

# git clone spring-petclinic
git clone https://github.com/liatrio/spring-petclinic.git
cd spring-petclinic

# package pet clinic
mvn clean package && \
cp target/petclinic.war /var/lib/tomcat/webapps/ && \
systemctl restart tomcat
