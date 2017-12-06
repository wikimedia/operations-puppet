class role::mediawiki::webserver {
    include ::role::mediawiki::common
    include ::apache::monitoring
    include ::profile::mediawiki::web
    include ::mediawiki::web::sites
    include ::mediawiki::packages::fonts
    # FIXME: These should all be merged into the generic sites class!
    if $::realm == 'labs' {
        include ::mediawiki::web::beta_sites
    } else {
        include ::mediawiki::web::prod_sites
    }

    if hiera('has_lvs', true) {
        include ::lvs::configuration
        include ::role::lvs::realserver

        # Conftool config
        include ::mediawiki::conftool

        # Restart HHVM if it is running since more than 3 days or
        # memory occupation exceeds 50% of the available RAM
        # This should prevent a series of cpu usage surges we've been seeing
        # on long-running HHVM processes. T147773
        $pool = $::role::lvs::realserver::lvs_pools['hhvm']['lvs_name']
        $lvs_service = pick($::lvs::configuration::lvs_services[$pool], {})
        $conftool_config = pick($lvs_service['conftool'], {'cluster' => 'appserver'})
        $module_path = get_module_path($module_name)
        $site_nodes = loadyaml("${module_path}/../../conftool-data/node/${::site}.yaml")
        $pool_nodes = keys($site_nodes[$::site][$conftool_config['cluster']])
        if member($pool_nodes, $::fqdn) {
            $times = cron_splay($pool_nodes, 'daily', 'hhvm-conditional-restarts')
            cron { 'hhvm-conditional-restart':
                command => '/usr/local/bin/hhvm-needs-restart > /dev/null && /usr/local/sbin/run-no-puppet /usr/local/bin/restart-hhvm > /dev/null',
                hour    => $times['hour'],
                minute  => $times['minute'],
            }
        }
    }

    ferm::service { 'mediawiki-http':
        proto   => 'tcp',
        notrack => true,
        port    => 'http',
        srange  => '$DOMAIN_NETWORKS',
    }

    # If a service check happens to run while we are performing a
    # graceful restart of Apache, we want to try again before declaring
    # defeat. See T103008.
    # We want to avoid false alarms during scheduled HHVM restarts (T147773),
    # so a higher retry_interval is needed.
    monitoring::service { 'appserver http':
        description    => 'Apache HTTP',
        check_command  => 'check_http_wikipedia',
        retries        => 2,
        retry_interval => 2,
    }

    monitoring::service { 'appserver_http_hhvm':
        description    => 'HHVM rendering',
        check_command  => 'check_http_wikipedia_main',
        retries        => 2,
        retry_interval => 2,
    }

    nrpe::monitor_service { 'hhvm':
        description  => 'HHVM processes',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1: -C hhvm',
    }
    if (hiera('role::mediawiki::webserver::tls', false)) {
        # TLSproxy instance to accept traffic on port 443
        if !getvar('pool') {
            $certs = [$::fqdn]
        }
        else {
            $pooldata = pick($::lvs::configuration::lvs_services[$pool], {})
            $certs = [pick($pooldata['icinga']['sites'][$::site]['hostname'], $::fqdn)]
        }

        include ::tlsproxy::nginx_bootstrap
        tlsproxy::localssl { 'unified':
            server_name    => 'www.wikimedia.org',
            certs          => $certs,
            certs_active   => $certs,
            default_server => true,
            do_ocsp        => false,
            upstream_ports => [80],
            access_log     => true,
        }

        monitoring::service { 'appserver https':
            description    => 'Nginx local proxy to apache',
            check_command  => 'check_https_url!en.wikipedia.org!/',
            retries        => 2,
            retry_interval => 2,
        }
        ferm::service { 'mediawiki-https':
            proto   => 'tcp',
            notrack => true,
            port    => 'https',
        }
    }
}
