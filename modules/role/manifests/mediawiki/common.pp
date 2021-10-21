class role::mediawiki::common {
    include profile::base::production
    include profile::mediawiki::scap_proxy
    include profile::mediawiki::common
    include profile::mediawiki::nutcracker

    include profile::mediawiki::mcrouter_wancache

    # proxy for connection to other servers
    include profile::services_proxy::envoy

    # Gather cpu/mem/network statistics per systemd.service
    include profile::prometheus::cadvisor_exporter
}
