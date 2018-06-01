class role::mediawiki::common {
    include ::standard
    include ::profile::mediawiki::scap_proxy
    include ::profile::mediawiki::common
    include ::profile::mediawiki::nutcracker

    include ::profile::mediawiki::mcrouter_wancache
    include ::profile::prometheus::mcrouter_exporter
}
