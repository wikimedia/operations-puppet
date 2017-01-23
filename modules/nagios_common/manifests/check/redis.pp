# == Class nagios_common::check::redis
#
# Installs the check_redis command and sets up
# the corresponding configuration

class nagios_common::check::redis(
    $config_dir = '/etc/icinga',
    $owner = 'icinga',
    $group = 'icinga'
    ) {

    require_package('libredis-perl')

    require ::passwords::redis

    file { '/etc/icinga/.redis_secret':
        ensure  => present,
        owner   => $owner,
        group   => $group,
        mode    => '0400',
        content => $::passwords::redis::main_password,
    }
    file { '/etc/icinga/.ores_redis_secret':
        ensure  => present,
        owner   => $owner,
        group   => $group,
        mode    => '0400',
        content => $::passwords::redis::ores_password,
    }

    ::nagios_common::check_command { 'check_redis':
        require    => [
            File["${config_dir}/commands"],
            Class['packages::libredis_perl']
        ],
        config_dir => $config_dir,
        owner      => $owner,
        group      => $group,

    }
}
