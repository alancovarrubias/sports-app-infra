# Use the official Jenkins base image
FROM jenkins/jenkins:latest

# Switch to the root user for Docker installation
USER root

# Install prerequisites
RUN apt-get update && \
    apt-get install -y curl

# Download and install Docker
RUN curl -fsSL https://get.docker.com -o get-docker.sh && \
    chmod +x get-docker.sh && \
    ./get-docker.sh

USER jenkins
