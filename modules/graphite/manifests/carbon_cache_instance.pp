define graphite::carbon_cache_instance {
    file { "/lib/systemd/system/carbon-cache@${title}.service":
        ensure  => 'link',
        target  => '/lib/systemd/system/carbon-cache@.service',
        require => File['/lib/systemd/system/carbon-cache@.service'],
    }

    service { "carbon-cache@${title}":
        ensure   => 'running',
        provider => 'systemd',
        enable   => true,
    }
}
