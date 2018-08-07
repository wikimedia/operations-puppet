class role::mediawiki::webserver {
    include ::role::mediawiki::common
    include ::apache::monitoring
    include ::mediawiki::web
    include ::mediawiki::web::sites
    include ::mediawiki::packages::fonts

    class { '::hhvm::admin': }

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

    # The apache2 systemd unit in stretch enables PrivateTmp by default
    # This makes "systemctl reload apache" fail with error code 226/EXIT_NAMESPACE
    # (which is a failure to setup a mount namespace). This is specific to our
    # mediawiki setup: Normally, with PrivateTmp enabled, /tmp would appear as
    # /tmp/systemd-private-$ID-apache2.service-$RANDOM and /var/tmp would appear as
    # /var/tmp/systemd-private-$ID-apache2.service-$RANDOM. That works fine for
    # /var/tmp, but fails for /tmp (so the reload only exposes the issue)
    #
    # Disable PrivateTmp on stretch for now; we can revisit this when phasing out HHVM.
    #
    # To disable, ship a custom systemd override when running on stretch; we have
    # a cleaner mechanism to pass an override via systemd::unit, but that would require
    # extensive changes and since the mediawiki classes are up for major refactoring
    # soon, add this via simple file references for now
    if os_version('debian >= stretch') {
        file { '/etc/systemd/system/apache2.service.d':
            ensure => directory,
            mode   => '0755',
            owner  => 'root',
            group  => 'root',
        }

        file { '/etc/systemd/system/apache2.service.d/override.conf':
            ensure  => present,
            mode    => '0755',
            owner   => 'root',
            group   => 'root',
            content => "[Service]\nPrivateTmp=false\n",
            notify  => Exec['systemctl-daemon-reload'],
        }

        exec { 'systemctl-daemon-reload':
            command     => '/bin/systemctl daemon-reload',
            refreshonly => true,
        }
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
