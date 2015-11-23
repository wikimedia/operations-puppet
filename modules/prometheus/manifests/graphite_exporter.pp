class prometheus::graphite_exporter (
    $config_file = 'graphite_exporter.conf',
) {
    require_package('prometheus-graphite-exporter')

    file { '/etc/prometheus':
        ensure => directory,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
    }

    file { '/etc/prometheus/graphite-exporter.conf':
        ensure => present,
        source => "puppet:///modules/${module_name}/${config_file}",
        mode   => '0444',
        owner  => 'root',
        group  => 'root',
        notify  => Service['prometheus-graphite-exporter'],
    }

    file { '/etc/default/prometheus-graphite-exporter':
        ensure  => present,
        content => "ARGS='-graphite.mapping-config=/etc/prometheus/graphite-exporter.conf -graphite.mapping-strict-match'\n",
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        notify  => Service['prometheus-graphite-exporter'],
    }

    base::service_unit { 'prometheus-graphite-exporter':
        ensure => present,
    }
}
