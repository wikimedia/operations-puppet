class role::mediawiki::common {
    include ::standard
    include ::profile::mediawiki::scap_proxy
    include ::profile::mediawiki::common
    include ::profile::mediawiki::nutcracker

    # Compatibility endpoint to syslog via logging pipeline
    include ::profile::rsyslog::kafka_shipper
    include ::profile::rsyslog::udp_localhost_compat

    include ::profile::mediawiki::mcrouter_wancache
    if os_version('debian >= stretch') {
        include ::profile::prometheus::mcrouter_exporter
    }
    # proxy for connection to other servers
    include ::profile::services_proxy
}
