FROM ubuntu:14.04
  
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    TERM=xterm
RUN locale-gen en_US en_US.UTF-8
RUN echo "export PS1='\e[1;31m\]\u@\h:\w\\$\[\e[0m\] '" >> /root/.bashrc
RUN apt-get update

# Runit
RUN apt-get install -y runit 
CMD export > /etc/envvars && /usr/sbin/runsvdir-start
RUN echo 'export > /etc/envvars' >> /root/.bashrc

# Utilities
RUN apt-get install -y vim less net-tools inetutils-ping wget curl git telnet nmap socat dnsutils netcat tree htop unzip sudo software-properties-common jq psmisc

# Install Oracle Java 8
RUN add-apt-repository ppa:webupd8team/java -y && \
    apt-get update && \
    echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections && \
    apt-get install -y oracle-java8-installer
ENV JAVA_HOME /usr/lib/jvm/java-8-oracle

#MySQL
RUN wget http://dev.mysql.com/get/mysql-apt-config_0.7.2-1_all.deb && \
    dpkg -i *.deb && \
    apt-get update
RUN apt-get install -y mysql-server

RUN wget -O - https://github.com/openzipkin/zipkin/archive/1.39.7.tar.gz | tar zx
RUN mv zipkin* zipkin
RUN cd zipkin && \
    ./gradlew assemble

#configuration
RUN sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mysql/my.cnf
COPY custom.cnf /etc/mysql/conf.d/

#data
COPY mysql.ddl /
RUN mysqld_safe & mysqladmin --wait=5 ping && \
    mysql < mysql.ddl && \
    mysql -uroot -Dzipkin < /zipkin/zipkin-anormdb/src/main/resources/mysql.sql && \
    mysqladmin shutdown

# Add runit services
COPY sv /etc/service 
ARG BUILD_INFO
LABEL BUILD_INFO=$BUILD_INFO
