# To build for multi-arch on Docker Desktop:
# 1. docker buildx create --name mybuilder --use
# 2. docker buildx build --push --platform linux/arm/v7,linux/arm64/v8,linux/amd64 -t $TAG .
# Details: https://cloudolife.com/2022/03/05/Infrastructure-as-Code-IaC/Container/Docker/Docker-buildx-support-multiple-architectures-images/
#TODO: add back etcdctl, kubectl, krew and it's plugins, amicontained, ConMachi
FROM ubuntu:24.10

RUN apt-get update \
    && apt-get install -yq nmap sudo curl socat iputils-ping vim bash dnsutils apt-file net-tools nmap stow tmux git-core sudo util-linux \
    jq ssh python2 tree ca-certificates\
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
RUN echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list

RUN apt-get update \
    && apt-get install -y kubectl \
    && rm -rf /var/lib/apt/lists/*

RUN curl -LO http://www.securitysift.com/download/linuxprivchecker.py \
    && sed -i 's/\/usr\/env python/\/usr\/env python2/' linuxprivchecker.py \
    && install ./linuxprivchecker.py /usr/local/bin \
    && ln -s /usr/bin/env /usr/env \
    && rm linuxprivchecker.py


RUN useradd -u 999 -G sudo -ms /bin/bash snyky \
  && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers \
  && echo 'export TERM=vt100' > /root/.bashrc

COPY --from=ericsmalling/gotty:latest /usr/bin/gotty /usr/local/bin/gotty
COPY "./gotty_config" "/opt/gotty.conf"

USER snyky:snyky

ENTRYPOINT ["/usr/local/bin/gotty"]

CMD ["--config","/opt/gotty.conf","/bin/bash"]
