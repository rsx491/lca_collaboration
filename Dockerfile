FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

ARG CI=false
ENV CI=${CI}

WORKDIR /

# 1. Update OS and install dependencies
RUN apt-get update \
 && apt-get dist-upgrade -y \
 && apt-get install -y apt-utils gnupg2 wget openjdk-17-jdk mc \
 && rm -rf /var/lib/apt/lists/*

# 2. Base directories
RUN mkdir -p /root/lca-cs

# 3. Install Tomcat
RUN groupadd tomcat9 \
 && useradd -s /bin/false -g tomcat9 -d /var/lib/tomcat9 tomcat9 \
 && mkdir -p /var/lib/tomcat9 \
 && wget https://archive.apache.org/dist/tomcat/tomcat-9/v9.0.76/bin/apache-tomcat-9.0.76.tar.gz \
 && tar xzvf apache-tomcat-9.0.76.tar.gz -C /var/lib/tomcat9 --strip-components=1 \
 && rm apache-tomcat-9.0.76.tar.gz \
 && chgrp -R tomcat9 /var/lib/tomcat9 \
 && chmod -R g+r /var/lib/tomcat9/conf \
 && chmod g+x /var/lib/tomcat9/conf \
 && chown -R tomcat9 /var/lib/tomcat9/webapps /var/lib/tomcat9/work /var/lib/tomcat9/temp /var/lib/tomcat9/logs

# 4. Artifact-dependent steps (SKIPPED IN CI)
RUN if [ "$CI" != "true" ]; then \
      echo "Local build: copying artifacts"; \
      mkdir -p /opt/cs/misc /opt/collab/lib/git; \
    else \
      echo "CI build: skipping application artifacts"; \
    fi

# 5. Minimal runtime for CI
CMD ["sleep", "infinity"]
