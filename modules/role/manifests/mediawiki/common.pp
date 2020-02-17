class role::mediawiki::common {
    include ::profile::standard
    include ::profile::mediawiki::scap_proxy
    include ::profile::mediawiki::common
    include ::profile::mediawiki::nutcracker

    include ::profile::mediawiki::mcrouter_wancache
    include ::profile::prometheus::mcrouter_exporter

    # proxy for connection to other servers
    # Temporary hiera lookup during transition
    # lint:ignore:wmf_styleguide
    if lookup('role::mediawiki::common::use_envoy_proxy', {'default_value' => false}) {
        include ::profile::services_proxy::envoy
    }
    # lint:endignore
    # We will remove this once the transition is done.
    include ::profile::services_proxy
}
