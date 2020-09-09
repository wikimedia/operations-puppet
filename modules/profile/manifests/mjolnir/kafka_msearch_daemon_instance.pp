define profile::mjolnir::kafka_msearch_daemon_instance(
  $ensure,
  $prometheus_port,
  $prometheus_nodes_ferm
) {
    $service_name = "mjolnir-kafka-msearch-daemon@${title}"

    ferm::service { "mjolnir-msearch-metrics_${title}":
      ensure => $ensure,
      proto  => 'tcp',
      port   => $prometheus_port,
      srange => "(@resolve((${prometheus_nodes_ferm})) @resolve((${prometheus_nodes_ferm}), AAAA))",
    }

    service { $service_name:
      ensure   => 'present' == $ensure,
      provider => 'systemd',
      enable   => 'present' == $ensure,
      require  => Systemd::Unit['mjolnir-kafka-msearch-daemon@.service'],
    }

    ::base::service_auto_restart { $service_name:
        ensure => $ensure,
    }
}
