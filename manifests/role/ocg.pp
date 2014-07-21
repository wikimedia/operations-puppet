# vim: set ts=4 et sw=4:
# role/ocg.pp
# Offline content generator for the MediaWiki collection extension

# Virtual resources for the monitoring server
@monitor_group { 'ocg_eqiad': description => 'offline content generator eqiad' }

class role::ocg::production {
    system::role { 'ocg': description => 'offline content generator for MediaWiki Collection extension' }

    include passwords::redis

    $service_port = 8000

    if ( $::ocg_redis_server_override != undef ) {
        $redis_host = $::ocg_redis_server_override
    } else {
        # Default host in the WMF production env... this needs a variable or something
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

    class { '::ocg':
        redis_host         => $redis_host,
        redis_password     => $passwords::redis::main_password,
        temp_dir           => '/mnt/tmpfs',
        service_port       => $service_port,
        statsd_host        => $statsd_host,
        statsd_is_txstatsd => 1,
        graylog_host       => $graylog_host,
    }

    ferm::service { 'ocg-http':
        proto => 'tcp',
        port   => $service_port,
        desc  => 'HTTP frontend to submit jobs and get status from pdf rendering',
        srange => $INTERNAL
    }

    monitor_service { 'ocg':
        description   => 'Offline Content Generation - Collection',
        check_command => 'check_http_on_port!80',
    }
}

class role::ocg::test {
    system::role { 'ocg-test': description => 'offline content generator for MediaWiki Collection extension (single host testing)' }

    include passwords::redis

    $service_port = 8000

    class { '::ocg':
        redis_host         => 'localhost',
        redis_password     => $passwords::redis::ocg_test_password,
        temp_dir           => '/srv/deployment/ocg/tmp',
        service_port       => $service_port,
        statsd_host        => 'statsd.eqiad.wmnet',
        statsd_is_txstatsd => 1
    }

    ferm::service { 'ocg-http':
        proto => 'tcp',
        port   => $service_port,
        desc  => 'HTTP frontend to submit jobs and get status from pdf rendering',
        srange => $INTERNAL
    }

    class { 'redis':
        maxmemory       => '500Mb',
        password        => $passwords::redis::ocg_test_password,
    }
}
