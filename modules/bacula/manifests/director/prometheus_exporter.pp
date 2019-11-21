class bacula::director::prometheus_exporter(
  $port = '9133',
) {
    require_package('python3-prometheus-client')
    file { '/usr/local/bin/prometheus-bacula-exporter.py':
        ensure => file,
        source => 'puppet:///modules/bacula/prometheus-bacula-exporter.py',
        owner  => 'bacula',
        group  => 'bacula',
        mode   => '0554',
    }
    systemd::service { 'prometheus-bacula-exporter':
        ensure  => present,
        restart => true,
        content => systemd_template('prometheus-bacula-exporter'),
        require => File['/usr/local/bin/prometheus-bacula-exporter.py'],
    }
}
