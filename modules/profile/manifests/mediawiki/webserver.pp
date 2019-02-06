class profile::mediawiki::webserver(
    Boolean $has_lvs = hiera('has_lvs'),
    Boolean $has_tls = hiera('profile::mediawiki::webserver::has_tls'),
    Optional[Wmflib::UserIpPort] $fcgi_port = hiera('profile::php_fpm::fcgi_port', undef),
    String $fcgi_pool = hiera('profile::mediawiki::fcgi_pool', 'www'),
    Mediawiki::Vhost_feature_flags $vhost_feature_flags = hiera('profile::mediawiki::vhost_feature_flags'),
) {
    include ::lvs::configuration
    include ::profile::mediawiki::httpd
    $fcgi_proxy = mediawiki::fcgi_endpoint($fcgi_port, $fcgi_pool)

    # Declare the proxies explicitly with retry=0
    httpd::conf { 'fcgi_proxies':
        ensure  => present,
        content => template('mediawiki/apache/fcgi_proxies.conf.erb')
    }

    # we need fonts!
    class { '::mediawiki::packages::fonts': }

    # Set feature flags for all mediawiki::web::vhost resources
    Mediawiki::Web::Vhost {
        php_fpm_fcgi_endpoint => $fcgi_proxy,
        feature_flags         => $vhost_feature_flags,
    }

    # Basic web sites
    class { '::mediawiki::web::sites': }


    class { '::hhvm::admin': }


    if $::realm == 'labs' {
        class { '::mediawiki::web::beta_sites': }
    }
    else {
        class { '::mediawiki::web::prod_sites':
            fcgi_proxy => $fcgi_proxy,
        }
    }

    if $has_lvs {
        require ::profile::lvs::realserver

        class { 'conftool::scripts': }
        conftool::credentials { 'mwdeploy':
            home => '/var/lib/mwdeploy',
        }

        # Will re-enable a mediawiki appserver after running scap pull
        file { '/usr/local/bin/mw-pool':
            ensure => present,
            source => 'puppet:///modules/mediawiki/mw-pool',
            owner  => 'root',
            group  => 'root',
            mode   => '0555',
        }

        monitoring::service { 'etcd_mw_config':
            ensure        => present,
            description   => 'MediaWiki EtcdConfig up-to-date',
            check_command => "check_etcd_mw_config_lastindex!${::site}",
        }

        # Restart HHVM if it is running since more than 3 days or
        # memory occupation exceeds 50% of the available RAM
        # This should prevent a series of cpu usage surges we've been seeing
        # on long-running HHVM processes. T147773

        # first load the list of all nodes in the current DC
        $module_path = get_module_path($module_name)
        $site_nodes = loadyaml("${module_path}/../../conftool-data/node/${::site}.yaml")[$::site]

        # Now build a non-flattened list of all servers in the site from all pools
        # configured here.
        $all_nodes = $::profile::lvs::realserver::pools.map |$pool, $data| {
            if $::lvs::configuration::lvs_services[$pool] {
                keys($site_nodes[$::lvs::configuration::lvs_services[$pool]['conftool']['cluster']])
            }
            else {
                []
            }
        }

        $pool_nodes = flatten($all_nodes)
        # If we are not in a pool it's not savy to restart hhvm
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
    # To disable, ship a custom systemd override when running on stretch
    if os_version('debian >= stretch') {
        systemd::unit { 'apache2.service':
            ensure   => present,
            content  => "[Service]\nPrivateTmp=false\n",
            override => true,
        }

        # TODO: remove once we have finished any transition
        file { '/etc/systemd/system/apache2.service.d/override.conf':
            ensure  => absent,
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
    if $has_tls {
        # TLSproxy instance to accept traffic on port 443
        require ::profile::tlsproxy::instance

        # Get the cert name from
        if $has_lvs {
            $all_certs = $::profile::lvs::realserver::pools.map |$pool, $data| {
                $lvs = pick($::lvs::configuration::lvs_services[$pool], {})
                if $lvs != {} and $lvs['icinga'] {
                    pick($lvs['icinga']['sites'][$::site]['hostname'], $::fqdn)
                }
                else {
                    $::fqdn
                }
            }
            $certs = unique($all_certs)
        }
        else {
            $certs = [$::fqdn]
        }

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
