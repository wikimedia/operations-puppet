class role::cache::base(
    $zero_site = 'https://zero.wikimedia.org',
    $purge_host_only_upload_re = '^upload\.wikimedia\.org$',
    $purge_host_not_upload_re = '^(?!upload\.wikimedia\.org)',
    $static_host = 'www.wikimedia.org',
    $static_wikihost = 'commons.wikimedia.org',
    $upload_domain = 'upload.wikimedia.org',
    $bits_domain = 'bits.wikimedia.org',
    $top_domain = 'org'
) {
    include standard
    include nrpe
    include lvs::configuration
    include role::cache::configuration
    include role::cache::statsd
    include network::constants
    include conftool::scripts

    # Only production needs these system perf tweaks
    if $::realm == 'production' {
        include role::cache::perf
    }

    # Not ideal factorization to put this here, but works for now
    class { 'varnish::zero_update':
        site         => $zero_site,
        auth_content => secret('misc/zerofetcher.auth'),
    }

    ###########################################################################
    # auto-depool on shutdown + conditional one-shot auto-pool on start
    # note: we can't use 'service' because we don't want to 'ensure =>
    # stopped|running', and 'service_unit' with 'declare_service => false'
    # wouldn't enable the service in systemd terms, either.
    ###########################################################################

    $tp_unit_path = '/lib/systemd/system/traffic-pool.service'
    $varlib_path = '/var/lib/traffic-pool'

    file { $tp_unit_path:
        ensure  => present,
        source  => 'puppet:///modules/role/cache/traffic-pool.service',
        mode    => '0444',
        owner   => root,
        group   => root,
    }

    file { $varlib_path:
        ensure => directory,
        mode   => '0755',
        owner  => root,
        group  => root,
    }

    exec { 'systemd reload+enable for traffic-pool':
        refreshonly => true,
        command     => '/bin/systemctl daemon-reload && /bin/systemctl enable traffic-pool',
        subscribe   => File[$tp_unit_path],
        require     => File[$varlib_path],
    }

    nrpe::monitor_systemd_unit_state { 'traffic-pool':
        require  => File[$tp_unit_path],
        critical => false, # promote to true once better-tested in the real world
    }
}
