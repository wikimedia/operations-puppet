class dumps::generation::server::statsender(
    $dumpsbasedir   = undef,
    $sender_address = undef,
    $user           = undef,
)  {
    $mail_package = debian::codename::ge('buster') ? {
        true    => 's-nail',
        default => 'heirloom-mailx',
    }
    ensure_packages($mail_package)

    file { '/usr/local/bin/get_dump_stats.sh':
        ensure  => 'present',
        mode    => '0755',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///modules/dumps/generation/get_dump_stats.sh',
        require => Package[$mail_package],
    }

    cron { 'dumps-stats-sender':
        ensure      => 'present',
        environment => 'MAILTO=ops-dumps@wikimedia.org',
        command     => "/bin/bash /usr/local/bin/get_dump_stats.sh --dumpsbasedir ${dumpsbasedir} --sender_address ${sender_address}",
        user        => $user,
        minute      => '30',
        hour        => '1',
        monthday    => '26',
        require     => File['/usr/local/bin/get_dump_stats.sh'],
    }
}
