class profile::parsoid(
    Boolean $has_lvs = hiera('has_lvs', true),
    Integer[1025, 65535] $port = lookup('profile::parsoid::port', {'default_value' => 8000}),
    Boolean $use_php = lookup('profile::parsoid::use_php', {'default_value' => false }),
) {
    if $has_lvs {
        require ::profile::lvs::realserver
    }

    if $use_php {

        require ::profile::mediawiki::scap_proxy
        require ::profile::mediawiki::common
        require ::profile::mediawiki::nutcracker
        require ::profile::mediawiki::mcrouter_wancache
        require ::profile::prometheus::mcrouter_exporter

        # proxy for connection to other servers
        require ::profile::services_proxy

        require ::profile::mediawiki::php
        require ::profile::mediawiki::php::monitoring
        require ::profile::mediawiki::webserver
    }

    class { '::service::configuration': }

    $mwapi_server = "${::service::configuration::mwapi_host}/w/api.php"
    class { '::parsoid':
        port         => $port,
        mwapi_server => $mwapi_server,
        mwapi_proxy  => '',
    }
}
