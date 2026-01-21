FROM debian:trixie-slim

ENV DEBIAN_FRONTEND=noninteractive
#ENV TZ=Europe/Paris
#RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update && apt-get install -y --no-install-recommends \
	ca-certificates \
	curl \
	gnupg \
	lsb-release \
        python3 \
        python3-pip \
        python3-dev \
        python3-setuptools \
        python3-wheel \
        gcc \
        libffi-dev \
        libssl-dev \
        libyaml-dev \
        git \
        bash \
        sudo \
        openssh-client \
	tini \
	vim \
	iproute2 \ 
	procps \
	dnsutils \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install docker
RUN mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/debian/gpg \
       | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
    && chmod a+r /etc/apt/keyrings/docker.gpg \
    && echo \
       "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
       https://download.docker.com/linux/debian trixie stable" \
       > /etc/apt/sources.list.d/docker.list \
    && apt-get update && apt-get install -y --no-install-recommends \
       docker-ce \
       docker-ce-cli \
       containerd.io \
       docker-buildx-plugin \
       docker-compose-plugin \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install docker-compose
RUN mkdir -p /usr/libexec/docker/cli-plugins \
 && curl -SL https://github.com/docker/compose/releases/download/v5.0.1/docker-compose-linux-x86_64 \
      -o /usr/libexec/docker/cli-plugins/docker-compose \
 && chmod +x /usr/libexec/docker/cli-plugins/docker-compose

# Upgrade pip and install ansible + molecule
ENV PIP_BREAK_SYSTEM_PACKAGES=1
RUN pip3 install --no-cache-dir ansible molecule molecule-docker docker ansible-lint flake8 yamllint

# Install ansible collections
RUN update-ca-certificates --fresh && export SSL_CERT_DIR=/etc/ssl/certs
RUN ansible-galaxy collection install ansible.netcommon ansible.posix ansible.utils ansible.windows codeaffen.phpipam community.docker community.general community.hashi_vault community.mysql community.vmware community.windows community.crypto community.libvirt confluent.platform crowdstrike.falcon devsec.hardening freeipa.ansible_freeipa grafana.grafana junipernetworks.junos prometheus.prometheus redpanda.cluster vmware.vmware fortinet.fortimanager gluster.gluster netbox.netbox community.postgresql

# Set Python interpreter for Ansible
ENV ANSIBLE_PYTHON_INTERPRETER=/usr/bin/python3
#ENV DOCKER_TLS_CERTDIR=""
#ENV DOCKER_TLS_VERIFY="0"

RUN sed -i "s/when: (lookup('env', 'HOME'))/when: lookup('env', 'HOME') | bool/" /usr/local/lib/python3.13/dist-packages/molecule_docker/playbooks/create.yml \
    && sed -i "s/when: (lookup('env', 'HOME'))/when: lookup('env', 'HOME') | bool/" /usr/local/lib/python3.13/dist-packages/molecule_docker/playbooks/destroy.yml

# Use tini as init, then start dockerd
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["dockerd", "--host=unix:///var/run/docker.sock", "--host=tcp://0.0.0.0:2375"]
