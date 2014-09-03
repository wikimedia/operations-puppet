# vim: set ts=4 et sw=4:
# role/ocg.pp
# Offline content generator for the MediaWiki collection extension

# Virtual resources for the monitoring server
@monitor_group { 'ocg_eqiad': description => 'offline content generator eqiad' }

class role::ocg::production (
        $tmpfs_size = '512M', # size of tmpfs filesystem e.g. 512M
        $tmpfs_mountpoint = '/mnt/tmpfs',
        $ocg_temp_size_warning  = '100M', # nagios warning threshold
        $ocg_temp_size_critical = '250M', # nagios critical threshold
    ) {

    system::role { 'ocg':
        description => 'offline content generator for MediaWiki Collection extension',
    }

    include passwords::redis

    $service_port = 8000

    if ( $::ocg_redis_server_override != undef ) {
        $redis_host = $::ocg_redis_server_override
    } else {
        # Default host in the WMF production env...
        # this needs a variable or something
        $redis_host = 'rdb1002.eqiad.wmnet'
    }

    if ( $::ocg_statsd_server_override != undef ) {
        $statsd_host = $::ocg_statsd_server_override
    } else {
        # Default host in the WMF production env
        $statsd_host = 'statsd.eqiad.wmnet'
    }

    if ( $::ocg_graylog_server_override != undef ) {
        $graylog_host = $::ocg_graylog_server_override
    } else {
        # Default host in the WMF production env
        $graylog_host = 'logstash1002.eqiad.wmnet'
    }

    file { $tmpfs_mountpoint:
        ensure => directory,
        owner  => 'root',
        group  => 'root',
    }

    mount { $tmpfs_mountpoint:
        ensure  => mounted,
        device  => 'tmpfs',
        fstype  => 'tmpfs',
        options => "nodev,nosuid,noexec,nodiratime,size=${tmpfs_size}",
        pass    => 0,
        dump    => 0,
        require => File[$tmpfs_mountpoint],
    }

    class { '::ocg':
        redis_host         => $redis_host,
        redis_password     => $passwords::redis::main_password,
        temp_dir           => $tmpfs_mountpoint,
        service_port       => $service_port,
        statsd_host        => $statsd_host,
        statsd_is_txstatsd => 1,
        graylog_host       => $graylog_host,
    }

    ferm::service { 'ocg-http':
        proto  => 'tcp',
        port   => $service_port,
        desc   => 'HTTP frontend to submit jobs and get status from pdf rendering',
        srange => $::INTERNAL
    }

    ferm::service{ 'gmond':
        proto  => 'tcp',
        port   => 8649,
        desc   => 'Ganglia monitor port (OCG config)',
        srange => $::INTERNAL
    }

    class { 'ocg::nagios::check':
        wtd => $ocg_temp_size_warning,
        ctd => $ocg_temp_size_critical,
        wod => '40G',
        cod => '50G',
        wpd => '1G',
        cpd => '2G',
        wjs => '20000',
        cjs => '30000',
        wrj => '100',
        crj => '500',
    }

    include lvs::configuration
    class { 'lvs::realserver': realserver_ips => $lvs::configuration::lvs_service_ips[$::realm]['ocg'][$::site] }
}

class role::ocg::test {
    system::role { 'ocg-test': description => 'offline content generator for MediaWiki Collection extension (single host testing)' }

    include passwords::redis

    $service_port = 8000

    class { '::ocg':
        redis_host         => 'localhost',
        redis_password     => $passwords::redis::ocg_test_password,
        service_port       => $service_port,
        statsd_host        => 'statsd.eqiad.wmnet',
        statsd_is_txstatsd => 1
    }

    ferm::service { 'ocg-http':
        proto  => 'tcp',
        port   => $service_port,
        desc   => 'HTTP frontend to submit jobs and get status from pdf rendering',
        srange => $::INTERNAL
    }

    class { 'redis':
        maxmemory       => '500Mb',
        password        => $passwords::redis::ocg_test_password,
    }
}
