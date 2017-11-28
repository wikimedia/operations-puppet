define graphite::carbon_cache_instance {
    $service_name = "carbon-cache@${title}"
    $log_dir = "/var/log/carbon/${service_name}"

    service { $service_name:
        ensure   => 'running',
        provider => 'systemd',
        enable   => true,
        require  => File['/lib/systemd/system/carbon-cache@.service'],
    }

    cron { "${service_name}-cleanup":
        command => "[ -d ${log_dir} ] && find ${log_dir} -type f -mtime +15 -iname '*.log.*' -delete",
        user    => '_graphite',
        hour    => fqdn_rand(24, $title),
        minute  => fqdn_rand(60, $title),
    }
}
