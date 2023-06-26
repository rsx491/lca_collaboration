FROM ubuntu:20.04

WORKDIR /

# 1. Update the OS and install dependencies

RUN apt-get update
RUN apt-get dist-upgrade -y
RUN apt-get install apt-utils gnupg2 wget openjdk-17-jdk -y
RUN apt-get install mc -y

# Prepare artifacts

RUN mkdir -p /root/lca-cs
COPY lib/collaboration-server-2.0.0-SNAPSHOT.war /root/lca-cs
COPY lib/collaboration-server-migration-2.0.0-jar-with-dependencies.jar /root/lca-cs
COPY lib/lca-collaboration-installer-2.0.0.config /root/lca-cs
COPY lib/application.properties /root/lca-cs
COPY lib/database /root/lca-cs/database
COPY lib/repository /root/lca-cs/repository
COPY lib/startup.sh /

# 3. Install Tomcat 

RUN groupadd tomcat9
RUN useradd -s /bin/false -g tomcat9 -d /var/lib/tomcat9 tomcat9
RUN mkdir /var/lib/tomcat9
RUN wget https://archive.apache.org/dist/tomcat/tomcat-9/v9.0.52/bin/apache-tomcat-9.0.52.tar.gz
RUN tar xzvf apache-tomcat-9.0.52.tar.gz -C /var/lib/tomcat9 --strip-components=1
RUN rm apache-tomcat-9.0.52.tar.gz
RUN chgrp -R tomcat9 /var/lib/tomcat9
RUN chmod -R g+r /var/lib/tomcat9/conf
RUN chmod g+x /var/lib/tomcat9/conf
RUN chown -R tomcat9 /var/lib/tomcat9/webapps/ /var/lib/tomcat9/work/ /var/lib/tomcat9/temp/ /var/lib/tomcat9/logs/

# 4. Run the installer

RUN chmod +x /startup.sh
# RUN java -jar /root/lca-cs/collaboration-server-migration-2.0.0-jar-with-dependencies.jar /root/lca-cs/lca-collaboration-installer-2.0.0.config
RUN chown tomcat9:tomcat9 /opt -R
RUN mkdir -p /opt/cs/misc
# RUN mkdir -p /opt/collab
RUN mkdir -p /opt/collab/lib/git
RUN chmod -R 777 /opt/collab
RUN cp /root/lca-cs/collaboration-server-migration-2.0.0-jar-with-dependencies.jar /opt/cs/misc/collaboration-server-migration-2.0.0-jar-with-dependencies.jar
RUN cp /root/lca-cs/lca-collaboration-installer-2.0.0.config /opt/cs/misc/lca-collaboration-installer-2.0.0.config
RUN cp /root/lca-cs/application.properties /opt/cs/misc/application.properties
RUN cp -R root/lca-cs/database /opt/collab/lib/database
RUN cp -R root/lca-cs/repository/. /opt/collab/lib/git/
RUN chmod +x /startup.sh


# 5. Copy webapp  
RUN rm /var/lib/tomcat9/webapps/* -r
RUN cp /root/lca-cs/collaboration-server-2.0.0-SNAPSHOT.war /var/lib/tomcat9/webapps/ROOT.war
RUN rm /root/lca-cs -r

# Entrypoint
# ENTRYPOINT ["/startup.sh"]
# CMD ["/bin/sh","/startup.sh", "/var/lib/tomcat9/bin/catalina.sh", "run"]

CMD /startup.sh ; sleep infinity
