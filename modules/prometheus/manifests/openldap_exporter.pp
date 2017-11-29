define prometheus::openldap_exporter () {
    include passwords::openldap::labs

    require_package('prometheus-openldap-exporter')

    $monitor_pass = $passwords::openldap::labs::monitor_pass
    file { '/etc/prometheus/openldap-exporter.yaml':
        ensure  => present,
        mode    => '0440',
        owner   => 'prometheus',
        group   => 'prometheus',
        content => template('role/openldap/prometheus.conf.erb'),
        notify  => Service['prometheus-openldap-exporter'],
    }

    service { 'prometheus-openldap-exporter':
        ensure  => running,
        require => File['prometheus-openldap-exporter'],
    }
}
