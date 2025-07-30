# SPDX-License-Identifier: Apache-2.0
FROM docker-registry.wikimedia.org/bullseye:20250723 AS debian-base

ARG C_USER=wikimedia

ARG DEBIAN_FRONTEND=noninteractive

RUN set -e; \
    BASE_PACKAGES="gnupg2 geoip-database sudo python3-toml ssl-cert git openssl libmaxminddb-dev python3-pip confd curl"; \
    WMF_PACKAGES="haproxy lua5.3-maxminddb"; \
    SUDOERS_FILE="/etc/sudoers.d/haproxy_test_nopasswd"; \
    echo 'deb http://apt.wikimedia.org/wikimedia bullseye-wikimedia thirdparty/haproxy28' > /etc/apt/sources.list.d/haproxy.list; \
    apt-get update; \
    apt-get install -y ${BASE_PACKAGES}; \
    apt-get install -y -t bullseye-wikimedia ${WMF_PACKAGES}; \
    adduser --home /${C_USER} --disabled-password --gecos "" ${C_USER}; \
    echo "${C_USER} ALL=(ALL) NOPASSWD: ALL" > ${SUDOERS_FILE}; \
    pip3 install --no-cache-dir jenkinsapi; \
    # Container images shouldn't fail for non-existent confd requirements
    ln -s /bin/true /usr/local/bin/confd-lint-wrap; \
    ln -s /bin/true /usr/bin/systemctl; \
    apt-get -y clean; \
    apt-get -y autoremove; \
    rm -rf /var/lib/apt/lists/*; \
    mkdir -p /run/haproxy; \
    mkdir -p /run/haproxy-secrets; \
    chown "$C_USER" /run/haproxy; \
    chown "$C_USER" /run/haproxy-secrets; \
    mkdir -p /etc/haproxy/conf.d; \
    mkdir -p /etc/haproxy/ipblocks.d; \
    chown -R "$C_USER" /etc/haproxy; \
    mkdir -p /etc/confd; \
    chown -R "$C_USER" /etc/confd

RUN set -e; \
    cat /etc/ssl/private/ssl-cert-snakeoil.key /etc/ssl/certs/ssl-cert-snakeoil.pem > /etc/haproxy/snakeoil.pem; \
    chown "$C_USER" /etc/haproxy/snakeoil.pem; \
    # crt-list must be moved to /run/haproxy to not be overrided by the one downloaded from PCC
    bash -c "echo '/etc/haproxy/snakeoil.pem *' > /run/haproxy/crt-list.cfg"; \
    chown "$C_USER" /run/haproxy/crt-list.cfg; \
    bash -c "for i in {1..3}; do openssl rand 80 | openssl base64 -A | xargs echo; done > /run/haproxy-secrets/stek.keys" ; \
    chown "$C_USER" /run/haproxy-secrets/stek.keys

USER ${C_USER}

COPY --chown=${C_USER}:${C_USER} confd_stub_data.yaml /etc/confd/
COPY usr/share/GeoIP/*.mmdb /usr/share/GeoIP/

WORKDIR "/$C_USER"

CMD ["/bin/bash"]
