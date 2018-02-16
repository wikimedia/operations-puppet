# == Define: prometheus::burrow_exporter
#
# Prometheus exporter for the Kafka Burrow Consumer lag monitoring daemon.
#
# = Parameters
#
# [*burrow_addr*]
#   The ip:port combination related to the Burrow daemon to poll.
#   Default: 'localhost:8000'
#
# [*metrics_addr*]
#   The ip:port combination where the exporter will expose its metrics.
#   Default: '0.0.0.0:8080'
#
# [*interval*]
#   How often the Burrow daemon is scraped in seconds.
#   Default: 30
#
define prometheus::burrow_exporter(
    $burrow_addr = 'localhost:8000',
    $metrics_addr = '0.0.0.0:9000',
    $interval = 30,
){
    require_package('prometheus-burrow-exporter')
    $service_name = "prometheus-burrow-exporter@${title}"

    $arguments = "--burrow-addr http://${burrow_addr} --metrics-addr ${metrics_addr} --interval ${interval}"

    # We're going with multiple prometheus-burrow-exporter, mask and stop the default one.
    exec { "mask_default_burrow_exporter_${title}":
        command => '/bin/systemctl mask prometheus-burrow-exporter.service ; /bin/systemctl stop prometheus-burrow-exporter.service',
        creates => '/etc/systemd/system/prometheus-burrow-exporter.service',
    }

    file { "/etc/default/${service_name}":
        ensure    => present,
        mode      => '0400',
        owner     => 'root',
        group     => 'root',
        content   => "ARGS=\"${arguments}\"",
        show_diff => false,
        notify    => Systemd::Service[$service_name],
    }

    systemd::service { $service_name:
        ensure  => present,
        content => systemd_template('prometheus-burrow-exporter@'),
        restart => true,
        require => Package['prometheus-burrow-exporter'],
    }
}