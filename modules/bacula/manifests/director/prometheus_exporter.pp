class bacula::director::prometheus_exporter(
  $port = '9133',
) {
    systemd::service { 'prometheus-bacula-exporter':
        ensure  => present,
        restart => true,
        content => systemd_template('prometheus-bacula-exporter'),
        require => File['/usr/local/bin/check_bacula.py'],
    }
}
