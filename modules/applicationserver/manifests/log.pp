class applicationserver::log {
    file { '/etc/logrotate.d/apache2':
        ensure  => present,
        source  => 'puppet:///modules/apache/logrotate-apache',
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
    }
}
