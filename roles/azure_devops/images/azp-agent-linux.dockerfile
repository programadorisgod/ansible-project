FROM ubuntu:24.04
ENV TARGETARCH="linux-x64"
# Also can be "linux-arm", "linux-arm64".

RUN apt update && \
    apt upgrade -y && \
    apt install -y curl git jq libicu74

# Install Azure CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

WORKDIR /azp/

COPY ./start.sh ./
RUN chmod +x ./start.sh

# Create agent user and set up home directory
RUN useradd -m -d /home/agent agent
RUN chown -R agent:agent /azp /home/agent

RUN apt update && apt install -y golang-go ca-certificates curl git && \
    install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc && \
    chmod a+r /etc/apt/keyrings/docker.asc && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" > /etc/apt/sources.list.d/docker.list && \
    apt update -y && \
    apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin


# Variables de entorno para Go
ENV GOPATH=/home/agent/go
ENV PATH=$GOPATH/bin:/usr/local/go/bin:$PATH

# Instalación de Node.js (versión LTS actual)
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && \
    apt install -y nodejs
USER root

RUN  usermod -aG docker agent


USER agent
# Another option is to run the agent as root.
# ENV AGENT_ALLOW_RUNASROOT="true"
RUN go version
RUN node -v
RUN npm -v
ENTRYPOINT [ "./start.sh" ]
