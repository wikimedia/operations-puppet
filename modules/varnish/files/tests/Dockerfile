FROM docker-registry.wikimedia.org/trixie AS debian-base

ARG C_USER=wikimedia

ARG DEBIAN_FRONTEND=noninteractive

RUN set -e; \
    BASE_PACKAGES="gnupg2 geoip-database sudo python3-toml"; \
    SUDOERS_FILE="/etc/sudoers.d/varnish_test_nopasswd"; \
    VARNISH_BASE="varnish varnish-modules varnish-re2 libvmod-netmapper libvmod-wmfuniq libmaxminddb-dev python3-pip confd libvmod-querysort libsodium-dev"; \
    apt-get update; \
    apt-get install -y ${BASE_PACKAGES}; \
    adduser --home /${C_USER} --disabled-password --gecos "" ${C_USER}; \
    chmod 0755 /${C_USER}; \
    echo "${C_USER} ALL=(ALL) NOPASSWD: ALL" > ${SUDOERS_FILE}; \
    apt-get update; \
    apt-get install --no-install-recommends -y ${VARNISH_BASE} python3-jenkinsapi; \
    ln -s /bin/true /usr/local/bin/confd-reload-vcl; \
    apt-get -y clean; \
    apt-get -y autoremove; \
    rm -rf /var/lib/apt/lists/*; \
    mkdir -p /etc/varnish/uniques.d;

USER ${C_USER}

COPY --chown=${C_USER}:${C_USER} public_clouds.json vendor_proxies.json /usr/share/varnish/tests/
COPY --chown=${C_USER}:${C_USER} confd_stub_data.yaml /${C_USER}/
ADD --chown=${C_USER}:${C_USER} stubs /${C_USER}/stubs
COPY dp.daily.key /etc/varnish/
COPY uniques.json /etc/varnish/
COPY keys.cfg /etc/varnish/uniques.d/
COPY --chown=vcache:varnish test.key /etc/varnish/uniques.d/
COPY usr/share/GeoIP/*.mmdb /usr/share/GeoIP/

WORKDIR /${C_USER}

CMD ["/bin/bash"]
