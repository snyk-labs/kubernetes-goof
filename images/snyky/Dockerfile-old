FROM ubuntu:24.10
LABEL maintainer="mattj"

EXPOSE 8080

WORKDIR /root

RUN export DEBIAN_FRONTEND=non-interactive && \
	apt-get -y update && \
    apt-get install -yq curl socat iputils-ping vim bash dnsutils apt-file net-tools nmap stow tmux git-core sudo util-linux\
    jq ssh python \
    && VERSION=v1.0.1 && \
    curl -sLk https://github.com/yudai/gotty/releases/download/$VERSION/gotty_linux_amd64.tar.gz \
    | tar xzC /usr/local/bin && \
    apt-get purge --auto-remove && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists*

COPY "./gotty_config" "/opt/gotty.conf"

# Setup Krew
RUN \
    ( \
    set -x; cd "$(mktemp -d)" \
    && curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/krew.{tar.gz,yaml}" \
    && tar zxvf krew.tar.gz \
    && ./krew-"$(uname | tr '[:upper:]' '[:lower:]')_amd64" install \
    --manifest=krew.yaml --archive=krew.tar.gz \
    ) \
    && rm -rf /tmp/tmp.*

# Install all krew plugins
COPY ./krew_plugin_list.txt /opt/
RUN $HOME/.krew/bin/kubectl-krew update \
     && $HOME/.krew/bin/kubectl-krew install < /opt/krew_plugin_list.txt

# Install kubectl
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl \
    && install ./kubectl /usr/local/bin/ \
    && rm ./kubectl

# Install etcdctl
RUN ETCD_VER=v3.4.15 \
    && DOWNLOAD_URL=https://storage.googleapis.com/etcd \
    && mkdir -p /tmp/etcd-download-test \
    && curl -L ${DOWNLOAD_URL}/${ETCD_VER}/etcd-${ETCD_VER}-linux-amd64.tar.gz -o /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz \
    && tar xzvf /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz -C /tmp/etcd-download-test --strip-components=1 \
    && rm -f /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz \
    && install /tmp/etcd-download-test/etcdctl /usr/local/bin/ \
    && rm -rf /tmp/etcd-download-test

RUN curl -LO https://github.com/genuinetools/amicontained/releases/latest/download/amicontained-linux-amd64 \
    && install amicontained-linux-amd64 /usr/local/bin/amicontained \
    && rm amicontained*

RUN curl -LO http://www.securitysift.com/download/linuxprivchecker.py \
    && install ./linuxprivchecker.py /usr/local/bin \
    && ln -s /usr/bin/env /usr/env \
    && rm linuxprivchecker.py

COPY "./ConMachi" "/usr/local/bin/conmachi"

RUN useradd -u 999 -G sudo -ms /bin/bash snyky \
  && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers \
  && echo 'export TERM=vt100' > /root/.bashrc

USER snyky:snyky

ENTRYPOINT ["/usr/local/bin/gotty"]

CMD ["--config","/opt/gotty.conf","/bin/bash"]
