class smokeping {
    package { 'smokeping':
        ensure => present,
    }

    package { 'curl':
        ensure => present,
    }

    file { '/etc/smokeping/config.d':
        ensure  => directory,
        recurse => true,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/smokeping/config.d',
        require => Package['smokeping'],
    }

    service { 'smokeping':
        ensure    => running,
        require   => [
            Package['smokeping'],
            File['/etc/smokeping/config.d'],
        ],
        subscribe => File['/etc/smokeping/config.d'],
    }
}
