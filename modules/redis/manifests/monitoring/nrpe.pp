class redis::monitoring::nrpe {
    ensure_packages('libredis-perl')

    nrpe::plugin { 'check_redis':
        source => 'puppet:///modules/redis/check_redis',
    }

    nrpe::plugin { 'nrpe_check_redis':
        source => 'puppet:///modules/redis/nrpe_check_redis.sh',
    }

    # TODO: remove
    file { [
        '/usr/lib/nagios/plugins/check_redis',
        '/usr/lib/nagios/plugins/nrpe_check_redis',
    ]:
        ensure => absent,
    }

    sudo::user { 'nagios_check_redis':
        ensure => absent,
    }
}
