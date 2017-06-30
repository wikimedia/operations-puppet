class profile::cumin::master (
    $puppetdb_host  = hiera('puppetmaster::puppetdb::master'),
    $cumin_log_path = '/var/log/cumin',
    $datacenters    = hiera('datacenters'),
) {
    ::keyholder::agent { 'cumin_master':
        trusted_groups => ['root'],
    }

    require_package(['cumin', 'python-yaml'])

    file { $cumin_log_path:
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0750',
    }

    file { '/etc/cumin':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0750',
    }

    file { '/etc/cumin/host_lists':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0750',
    }

    file { '/etc/cumin/config.yaml':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0640',
        content => template('profile/cumin/config.yaml.erb'),
        require => File['/etc/cumin'],
    }

    file { '/etc/cumin/cache-generator-config.yaml':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0640',
        content => template('profile/cumin/cache-generator-config.yaml.erb'),
        require => File['/etc/cumin'],
    }

    file { '/usr/local/sbin/cumin-cache-generator':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0750',
        source  => 'puppet:///modules/profile/cumin/cumin_cache_generator.py',
        require => [
            File['/etc/cumin/host_lists'],
            File['/etc/cumin/cache-generator-config.yaml'],
            Package['python-yaml'],
        ],
    }

    cron { 'cumin-cache-generator':
        ensure  => present,
        user    => 'root',
        command => '/usr/local/sbin/cumin-cache-generator',
        hour    => '4',
        minute  => '19',
        require => File['/usr/local/sbin/cumin-cache-generator'],
    }

}
