define graphite::carbon_cache_instance {
    $service_name = "carbon-cache@${title}"
    $log_dir = "/var/log/carbon/${service_name}"

    service { $service_name:
        ensure   => 'running',
        provider => 'systemd',
        enable   => true,
        require  => File['/lib/systemd/system/carbon-cache@.service'],
    }

    systemd::tmpfile{ "${service_name}-logs-cleanup":
      ensure  => 'present',
      content => "e ${log_dir} - - - 15d",
    }
}
