# Use the official Jenkins base image
FROM jenkins/jenkins:latest

# Switch to the root user for Docker installation
USER root

# Install prerequisites
RUN apt-get update && \
    apt-get install -y curl && \
    apt-get install -y python3-pip && \
    rm /usr/lib/python3.11/EXTERNALLY-MANAGED && \
    pip3 install --no-cache-dir awscli

# Download and install Docker
RUN curl -fsSL https://get.docker.com -o get-docker.sh && \
    chmod +x get-docker.sh && \
    ./get-docker.sh

USER jenkins
RUN mkdir /var/jenkins_home/casc_configs
RUN mkdir /var/jenkins_home/.aws
COPY --chown=jenkins:jenkins config /var/jenkins_home/.aws/config
COPY --chown=jenkins:jenkins credentials /var/jenkins_home/.aws/credentials
COPY --chown=jenkins:jenkins plugins.txt /usr/share/jenkins/ref/plugins.txt
ENV CASC_JENKINS_CONFIG=/var/jenkins_home/casc_configs
RUN jenkins-plugin-cli -f /usr/share/jenkins/ref/plugins.txt
