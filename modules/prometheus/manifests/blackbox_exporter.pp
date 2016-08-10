# Prometheus black box metrics exporter. See also
# https://github.com/prometheus/blackbox_exporter
#
# This does 'active' checks over TCP / UDP / ICMP / HTTP / DNS
# and reports status to the prometheus scraper

class prometheus::blackbox_exporter{
    requires_os('debian >= jessie')

    require_package('prometheus-blackbox-exporter')

    file { '/etc/prometheus-blackbox_exporter.yml':
        ensure  => present,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('prometheus/blackbox_exporter.yml.erb'),
        notify  => Service['prometheus-blackbox-exporter'],
    }

    base::service_unit { 'prometheus-blackbox-exporter':
        ensure  => present,
        refresh => true,
        systemd => true,
        require => Package['prometheus-blackbox-exporter'],
    }
}
