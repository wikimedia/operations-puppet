FROM debian:buster-slim AS debian-base

ARG C_USER=wikimedia

ARG DEBIAN_FRONTEND=noninteractive

RUN set -e; \
    BASE_PACKAGES="wget gnupg2 geoip-database geoip-database-extra sudo python3-toml"; \
    REPO_DIR="/etc/apt/sources.list.d"; \
    REPO="buster-wikimedia"; \
    WIKIMEDIA_REPO="deb http://apt.wikimedia.org/wikimedia ${REPO}"; \
    WIKIMEDIA_REPO_FILE="${REPO_DIR}/wikimedia.list"; \
    SUDOERS_FILE="/etc/sudoers.d/varnish_test_nopasswd"; \
    VARNISH_BASE="varnish varnish-modules libvmod-netmapper libvmod-re2 libmaxminddb-dev python3-pip confd libvmod-querysort libsodium-dev"; \
    apt-get update; \
    apt-get install -y ${BASE_PACKAGES}; \
    adduser --home /${C_USER} --disabled-password --gecos "" ${C_USER}; \
    echo "${C_USER} ALL=(ALL) NOPASSWD: ALL" > ${SUDOERS_FILE}; \
    echo "${WIKIMEDIA_REPO} main" > ${WIKIMEDIA_REPO_FILE}; \
    wget --quiet "https://wikitech.wikimedia.org/w/index.php?title=APT_repository/Stretch-Key&action=raw" -O - | apt-key add -; \
    apt-get update; \
    apt-get install --no-install-recommends -t "${REPO}" -y ${VARNISH_BASE}; \
    pip3 install --no-cache-dir jenkinsapi; \
    ln -s /bin/true /usr/local/bin/confd-reload-vcl; \
    apt-get purge -y wget; \
    apt-get -y clean; \
    apt-get -y autoremove; \
    rm -rf /var/lib/apt/lists/*;

USER ${C_USER}

COPY --chown=${C_USER}:${C_USER} public_clouds.json trusted_proxies.json vendor_proxies.json /usr/share/varnish/tests/
COPY --chown=${C_USER}:${C_USER} confd_stub_data.yaml /${C_USER}/
COPY dp.daily.key /etc/varnish/
COPY usr/share/GeoIP/*.mmdb /usr/share/GeoIP/

WORKDIR /${C_USER}

CMD ["/bin/bash"]
