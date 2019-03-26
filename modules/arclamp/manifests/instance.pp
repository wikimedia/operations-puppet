define arclamp::instance(
    Hash $config,
    String $description,
    Wmflib::Ensure $ensure = 'present',
) {
    # Verify the title will not create us any issues
    assert_type(Pattern[/[a-z]+/], $title)

    file { "/etc/arclamp-log-${title}.yaml":
        ensure  => $ensure,
        content => ordered_yaml($config),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service["${title}-log"],
    }

    systemd::service { "${title}-log":
        ensure    => $ensure,
        content   => systemd_template('arclamp-log'),
        subscribe => File['/usr/local/bin/arclamp-log'],
        require   => File['/srv/xenon']
    }
}
