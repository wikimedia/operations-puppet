class redis::monitoring::nrpe {
    require_package('libredis-perl')

    # TODO: move the source here once we're done with the migration
    file { '/usr/lib/nagios/plugins/check_redis':
        ensure => present,
        source => 'puppet:///modules/nagios_common/check_commands/check_redis',
        mode   => '0755',
    }

    $nrpe_command = '/usr/lib/nagios/plugins/nrpe_check_redis'
    file { $nrpe_command:
        ensure => present,
        source => 'puppet:///modules/redis/nrpe_check_redis.sh',
        mode   => '0755',
    }

    sudo::user { 'nagios_check_redis':
        ensure     => present,
        user       => 'nagios',
        privileges => ["ALL = NOPASSWD: ${nrpe_command}"],
        require    => File[$nrpe_command],
    }
}
