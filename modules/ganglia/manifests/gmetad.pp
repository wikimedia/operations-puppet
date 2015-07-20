class ganglia::gmetad(
        $ensure='present',
        $grid,
        $rrd_rootdir,
        $gmetad_root,
        $rrdcached_socket,
        $authority,
        $trusted_hosts,
        $data_sources,
        $rra_sizes,
) {

    package { 'gmetad':
        ensure => $ensure,
    }

    file { $gmetad_root:
        ensure => directory,
        owner  => 'ganglia',
        group  => 'ganglia',
        mode   => '0755',
    }
    file { $rrd_rootdir:
        ensure => directory,
        owner  => 'nobody',
        group  => 'root',
        mode   => '0755',
    }

    file { '/etc/ganglia/gmetad.conf':
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('ganglia/gmetad.conf.erb'),
    }

    service { 'gmetad':
        ensure   => ensure_service($ensure),
        provider => 'upstart',
    }

    # We override the shipped by ubuntu upstart. We want to use rrdcached
    file { '/etc/init/gmetad.conf':
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('ganglia/gmetad.upstart'),
    }

    # We also notify on file changes
    Package['gmetad'] -> File['/etc/ganglia/gmetad.conf'] ~> Service['gmetad']
    Package['gmetad'] -> File['/etc/init/gmetad.conf'] ~> Service['gmetad']
    File[$gmetad_root] -> File[$rrd_rootdir]
    File[$rrd_rootdir] -> Service['gmetad']
}
