define graphite::carbon_cache_instance {
    service { "carbon-cache@${title}":
        ensure   => 'running',
        provider => 'systemd',
        enable   => true,
        require  => File['/lib/systemd/system/carbon-cache@.service'],
    }
}
