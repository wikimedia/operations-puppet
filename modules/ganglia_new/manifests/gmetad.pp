class ganglia_new::gmetad(
        $ensure='present',
        $grid,
        $rrd_rootdir,
        $rrdcached_socket,
        $authority,
        $trusted_hosts,
        $data_sources,
        $rra_sizes,
) {

    package { 'gmetad':
        ensure => $ensure,
    }

    file { '/etc/ganglia/gmetad.conf':
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('ganglia_new/gmetad.conf.erb'),
    }

    service { 'gmetad':
        ensure   => ensure_service($ensure),
        provider => 'upstart',
    }

    # We override the shipped by ubuntu upstart. We want to use rrdcached
    file { '/etc/init/gmetad.conf':
        ensure => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('ganglia_new/gmetad.upstart'),
    }

    Package['gmetad'] -> File['/etc/ganglia/gmetad.conf'] -> Service['gmetad']
    Package['gmetad'] -> File['/etc/init/gmetad.conf'] -> Service['gmetad']
}
