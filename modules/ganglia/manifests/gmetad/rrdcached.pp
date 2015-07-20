# Only support trusty
class ganglia::gmetad::rrdcached(
    $ensure='present',
    $rrdpath,
    $gmetad_socket,
    $gweb_socket,
    $journal_dir='/var/lib/rrdcached/journal',
) {
    package { 'rrdcached':
        ensure => $ensure,
    }

    file { $journal_dir:
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { '/etc/default/rrdcached':
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('ganglia/rrdcached.default.erb'),
    }

    service { 'rrdcached':
        ensure   => ensure_service($ensure),
        provider => 'upstart',
    }

    # We also notify on file changes
    Package['rrdcached'] -> File['/etc/default/rrdcached'] ~> Service['rrdcached']
}
