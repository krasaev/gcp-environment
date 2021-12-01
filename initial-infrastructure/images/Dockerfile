FROM jenkins/inbound-agent:latest-jdk17-preview

ENV DOCKER_VERSION=20.10.9 DOCKER_COMPOSE_VERSION=2.1.1 KUBECTL_VERSION=v1.22.0 HELM_VERSION=v3.7.1 \
DOCKER_CREDENTIAL_GCR_VERION=2.1.0

USER root

RUN apt-get update && apt-get install -y \
curl

RUN curl -fsSLO "https://github.com/GoogleCloudPlatform/docker-credential-gcr/releases/download/v${DOCKER_CREDENTIAL_GCR_VERION}/docker-credential-gcr_linux_amd64-${DOCKER_CREDENTIAL_GCR_VERION}.tar.gz" \
    && tar -xvzf docker-credential-gcr_linux_amd64-${DOCKER_CREDENTIAL_GCR_VERION}.tar.gz -C /usr/local/bin \
    && chmod -R +x /usr/local/bin/docker-credential-gcr

RUN curl -fsSLO https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz \
		&& tar --strip-components=1 -xvzf docker-${DOCKER_VERSION}.tgz -C /usr/local/bin \
		&& chmod -R +x /usr/local/bin/docker

RUN curl -L https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-Linux-x86_64 -o /usr/local/bin/docker-compose \
    && chmod +x /usr/local/bin/docker-compose

RUN curl -L https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl \
    && chmod +x /usr/local/bin/kubectl

RUN curl -fsSLO https://get.helm.sh/helm-${HELM_VERSION}-linux-386.tar.gz \
		&& tar --strip-components=1 -xvzf helm-${HELM_VERSION}-linux-386.tar.gz -C /usr/local/bin \
		&& chmod -R +x /usr/local/bin/helm

#FIXME user non root user, configure access to docker
#RUN groupadd docker
#
#RUN usermod -aG docker jenkins
#
#USER jenkins