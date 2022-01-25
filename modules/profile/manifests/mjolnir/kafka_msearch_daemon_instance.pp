define profile::mjolnir::kafka_msearch_daemon_instance(
  $ensure,
) {
    $service_name = "mjolnir-kafka-msearch-daemon@${title}"

    service { $service_name:
      ensure   => 'present' == $ensure,
      provider => 'systemd',
      enable   => 'present' == $ensure,
      require  => Systemd::Unit['mjolnir-kafka-msearch-daemon@.service'],
    }

    ::profile::auto_restarts::service { $service_name:
        ensure => $ensure,
    }
}
