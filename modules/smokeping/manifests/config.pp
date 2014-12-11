class smokeping::config {
    Package['smokeping'] -> Class['smokeping::config']

    file { '/etc/smokeping/config.d':
        ensure  => directory,
        require => Package['smokeping'],
        recurse => true,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/smokeping/config.d',
    }
}
