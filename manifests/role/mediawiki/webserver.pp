class role::mediawiki::webserver($pool) {
    include ::role::mediawiki::common
    include ::apache::monitoring
    include ::mediawiki::web
    # HACK: Fix to not be different classes!
    if $::realm == 'labs' {
        include ::mediawiki::web::beta_sites
    } else {
        include ::mediawiki::web::prod_sites
    }

    if hiera('has_lvs', true) {
        include ::lvs::configuration
        $ips = $lvs::configuration::service_ips[$pool][$::site]

        class { 'lvs::realserver':
            realserver_ips => $ips,
        }
    }

    ferm::service { 'mediawiki-http':
        proto   => 'tcp',
        notrack => true,
        port    => 'http',
    }

    # If a service check happens to run while we are performing a
    # graceful restart of Apache, we want to try again before declaring
    # defeat. See T103008.
    monitoring::service { 'appserver http':
        description   => 'Apache HTTP',
        check_command => 'check_http_wikipedia',
        retries       => 2,
    }

    if os_version('ubuntu >= trusty') {
        monitoring::service { 'appserver_http_hhvm':
            description   => 'HHVM rendering',
            check_command => 'check_http_wikipedia_main',
            retries       => 2,
        }

        nrpe::monitor_service { 'hhvm':
            description  => 'HHVM processes',
            nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1: -C hhvm',
        }
    }

}

