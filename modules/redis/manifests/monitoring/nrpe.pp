class redis::monitoring::nrpe {
    ensure_packages('libredis-perl')

    nrpe::plugin { 'check_redis':
        source => 'puppet:///modules/redis/check_redis',
    }

    # TODO: change to ensure => absent after a full puppet cycle, then remove completely after another
    file { '/usr/lib/nagios/plugins/check_redis':
        ensure => present,
        source => 'puppet:///modules/redis/check_redis',
        mode   => '0755',
    }

    $old_nrpe_command = '/usr/lib/nagios/plugins/nrpe_check_redis'
    nrpe::plugin { 'nrpe_check_redis':
        source => 'puppet:///modules/redis/nrpe_check_redis.sh',
    }
    # TODO: change to ensure => absent after a full puppet cycle, then remove completely after another
    file { $old_nrpe_command:
        ensure => present,
        source => 'puppet:///modules/redis/nrpe_check_redis.sh',
        mode   => '0755',
    }

    sudo::user { 'nagios_check_redis':
        ensure     => present,
        user       => 'nagios',
        privileges => [
            "ALL = NOPASSWD: ${old_nrpe_command}",
            'ALL = NOPASSWD: /usr/local/lib/nagios/plugins/nrpe_check_redis',
        ],
        require    => File[$old_nrpe_command],
    }
}
