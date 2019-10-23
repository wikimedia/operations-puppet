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
        include ::profile::mediawiki::php::restarts
        require ::profile::mediawiki::webserver
        # Temporarily allow scap3 to restart php-fpm.
        # This is going away, see T236275
        # Also yes, this is all hardcoded as it's going away soon (TM)
        sudo::user { 'scap3_restart_php':
            user       => 'deploy-service',
            privileges => ['ALL = (root) NOPASSWD: /usr/local/sbin/check-and-restart-php php7.2-fpm *'],
        }
    }

    class { '::service::configuration': }

    $mwapi_server = "${::service::configuration::mwapi_host}/w/api.php"
    class { '::parsoid':
        port         => $port,
        mwapi_server => $mwapi_server,
        mwapi_proxy  => '',
    }
}
