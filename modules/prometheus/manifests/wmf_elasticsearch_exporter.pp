class prometheus::wmf_elasticsearch_exporter {
    file { '/usr/local/bin/prometheus-wmf-elasticsearch-exporter':
        ensure  => present,
        content => 'puppet:///modules/prometheus/usr/local/bin/prometheus-wmf-elasticsearch-exporter',
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
    }

    systemd::service { 'prometheus-wmf-elasticsearch-exporter':
        ensure  => present,
        restart => true,
        content => systemd_template('prometheus-wmf-elasticsearch-exporter'),
        require => File['/usr/local/bin/prometheus-wmf-elasticsearch-exporter'],
    }
}
