class role::cache::base(
    $zero_site = 'https://zero.wikimedia.org',
    $purge_host_only_upload_re = '^upload\.wikimedia\.org$',
    $purge_host_not_upload_re = '^(?!upload\.wikimedia\.org)',
    $storage_parts = ['sda3', 'sdb3'],
) {
    include ::standard
    require ::profile::conftool::client
    include nrpe
    include lvs::configuration
    include network::constants
    include conftool::scripts
    include ::role::prometheus::varnish_exporter


    $cache_cluster = hiera('cache::cluster')

    system::role { "role::cache::${cache_cluster}":
        description => "${cache_cluster} Varnish cache server",
    }

    # Only production needs system perf tweaks and NFS client disable
    if $::realm == 'production' {
        include role::cache::perf
        include base::no_nfs_client
    }

    # Not ideal factorization to put this here, but works for now
    class { 'varnish::zero_update':
        site         => $zero_site,
    }

    # XXX: temporary, we need this to mitigate T145661
    if $::realm == 'production' {
        $hnodes = hiera("cache::${cache_cluster}::nodes")
        $all_nodes = array_concat($hnodes['eqiad'], $hnodes['esams'], $hnodes['ulsfo'], $hnodes['codfw'])
        $times = cron_splay($all_nodes, 'weekly', "${cache_cluster}-backend-restarts")
        $be_restart_h = $times['hour']
        $be_restart_m = $times['minute']
        $be_restart_d = $times['weekday']

        file { '/etc/cron.d/varnish-backend-restart':
            mode    => '0444',
            owner   => 'root',
            group   => 'root',
            content => template('varnish/varnish-backend-restart.cron.erb'),
            require => File['/usr/local/sbin/varnish-backend-restart'],
        }
    }

    ###########################################################################
    # Analytics/Logging stuff
    ###########################################################################

    # Client connection stats from the 'X-Connection-Properties'
    # header set by the SSL terminators.
    ::varnish::logging::xcps { 'xcps':
        statsd_server => hiera('statsd'),
    }

    ::varnish::logging::statsd { 'default':
        statsd_server => hiera('statsd'),
        key_prefix    => "varnish.${::site}.backends",
    }

    # Install a varnishkafka producer to send
    # varnish webrequest logs to Kafka.
    class { 'role::cache::kafka::webrequest':
        topic => "webrequest_${cache_cluster}",
    }

    # Parse varnishlogs for request statistics and send to statsd.
    varnish::logging::reqstats { 'frontend':
        key_prefix => "varnish.${::site}.${cache_cluster}.frontend.request",
        statsd     => hiera('statsd'),
    }

    ::varnish::logging::xcache { 'xcache':
        key_prefix    => "varnish.${::site}.${cache_cluster}.xcache",
        statsd_server => hiera('statsd'),
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
        ensure => present,
        source => 'puppet:///modules/role/cache/traffic-pool.service',
        mode   => '0444',
        owner  => 'root',
        group  => 'root',
    }

    file { $varlib_path:
        ensure => directory,
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
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


    ###########################################################################
    # Storage configuration
    ###########################################################################

    # everything from here down is related to backend storage/weight config

    $storage_size = $::hostname ? {
        /^cp1008$/          => 117, # Intel X-25M 160G (test host!)
        /^cp30(0[3-9]|10)$/ => 460, # Intel M320 600G via H710
        /^cp400[1234]$/     => 220, # Seagate ST9250610NS - 250G (only non-SSD left!)
        /^cp[0-9]{4}$/      => 360, # Intel S3700 400G (prod default)
        default             => 6,   # 6 is the bare min, for e.g. virtuals
    }

    $filesystems = unique($storage_parts)
    varnish::setup_filesystem { $filesystems: }
    Varnish::Setup_filesystem <| |> -> Varnish::Instance <| |>

    $file_storage_args = join([
        "-s main1=file,/srv/${storage_parts[0]}/varnish.main1,${storage_size}G",
        "-s main2=file,/srv/${storage_parts[1]}/varnish.main2,${storage_size}G",
    ], ' ')
}
