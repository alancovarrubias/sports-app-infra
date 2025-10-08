# Use the official Jenkins base image
FROM jenkins/jenkins:lts-jdk17

# Switch to the root user for Docker installation
USER root

# Install prerequisites
RUN apt-get update && \
    apt-get install -y curl && \
    apt-get install -y python3-pip && \
    apt-get install -y docker-compose && \
    rm /usr/lib/python3.11/EXTERNALLY-MANAGED && \
    pip3 install --no-cache-dir awscli

# deps
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    git curl build-essential libssl-dev zlib1g-dev libreadline-dev libyaml-dev libffi-dev \
    libgdbm-dev libncurses5-dev ca-certificates bzip2 && rm -rf /var/lib/apt/lists/*

# rbenv
ENV RBENV_ROOT=/usr/local/rbenv
ENV PATH=${RBENV_ROOT}/bin:${RBENV_ROOT}/shims:${PATH}
RUN git clone https://github.com/rbenv/rbenv.git ${RBENV_ROOT} && \
    git clone https://github.com/rbenv/ruby-build.git ${RBENV_ROOT}/plugins/ruby-build && \
    ${RBENV_ROOT}/plugins/ruby-build/install.sh && \
    printf 'export RBENV_ROOT=%s\nexport PATH="$RBENV_ROOT/bin:$RBENV_ROOT/shims:$PATH"\n' "$RBENV_ROOT" \
    > /etc/profile.d/rbenv.sh && echo 'eval "$(rbenv init - bash)"' >> /etc/profile.d/rbenv.sh && \
    ls -la /usr/local && ls -la ${RBENV_ROOT}

# build Ruby
ENV RUBY_VERSION=3.3.4
RUN bash -lc 'rbenv install -s ${RUBY_VERSION} && rbenv global ${RUBY_VERSION} && gem install --no-document bundler && rbenv rehash'

# Install terraform
RUN apt-get update && apt-get install -y gnupg software-properties-common
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | \
    gpg --dearmor | \
    tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
RUN echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
    https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
    tee /etc/apt/sources.list.d/hashicorp.list
RUN apt update
RUN apt-get install terraform

# Download and install Docker
RUN curl -fsSL https://get.docker.com -o get-docker.sh && \
    chmod +x get-docker.sh && \
    ./get-docker.sh

# Configure Jenkins and install plugins
USER jenkins
RUN mkdir /var/jenkins_home/casc_configs
RUN mkdir /var/jenkins_home/.aws
COPY --chown=jenkins:jenkins .aws/config /var/jenkins_home/.aws/config
COPY --chown=jenkins:jenkins .aws/credentials /var/jenkins_home/.aws/credentials
COPY --chown=jenkins:jenkins plugins.txt /usr/share/jenkins/ref/plugins.txt
ENV CASC_JENKINS_CONFIG=/var/jenkins_home/casc_configs
RUN jenkins-plugin-cli -f /usr/share/jenkins/ref/plugins.txt