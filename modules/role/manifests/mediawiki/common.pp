class role::mediawiki::common {
    include ::profile::standard
    include ::profile::mediawiki::scap_proxy
    include ::profile::mediawiki::common
    include ::profile::mediawiki::nutcracker

    include ::profile::mediawiki::mcrouter_wancache
    include ::profile::prometheus::mcrouter_exporter

    # proxy for connection to other servers
    include ::profile::services_proxy
}
