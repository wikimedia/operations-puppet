# Only support trusty
class ganglia_new::gmetad::rrdcached(
    $ensure='present',
    $rrdpath,
    $gmetasocket,
    $gwebsocket,
) {
    package { 'rrdcached':
        ensure => $ensure,
    }

    file { '/etc/default/rrdcached':
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('ganglia_new/rrdcached.default.erb'),
    }

    service { 'rrdcached':
        ensure   => $ensure,
        provider => 'upstart',
    }

    Package['rrdcached'] -> File['/etc/default/rrdcached'] -> Service['rrdcached']
}
