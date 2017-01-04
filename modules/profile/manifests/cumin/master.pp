class profile::cumin::master (
    $puppetdb_host  = hiera('puppetmaster::puppetdb::master'),
    $cumin_log_path = '/var/log/cumin',
) {
    ::keyholder::agent { 'cumin_master':
        trusted_groups => ['root'],
    }

    require_package('cumin')

    file { $cumin_log_path:
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0750',
        require => Package['cumin'],
    }

    file { '/etc/cumin':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0750',
        require => Package['cumin'],
    }

    file { '/etc/cumin/config.yaml':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0640',
        content => template('profile/cumin/config.yaml.erb'),
        require => File['/etc/cumin'],
    }
}
