# Only support trusty
class ganglia_new::gmetad::rrdcached(
    $ensure='present',
    $rrdpath,
    $gmetad_socket,
    $gweb_socket,
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
        ensure   => ensure_service($ensure),
        provider => 'upstart',
    }

    Package['rrdcached'] -> File['/etc/default/rrdcached'] -> Service['rrdcached']
}
