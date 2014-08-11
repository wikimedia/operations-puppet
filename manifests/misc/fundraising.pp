class misc::fundraising::udp2log_rotation {

    include role::logging::systemusers

    sudo_user { 'file_mover':
        privileges => ['ALL = NOPASSWD: /usr/bin/killall -HUP udp2log'] }

    file { '/usr/local/bin/rotate_fundraising_logs':
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        source  => 'puppet:///files/misc/scripts/rotate_fundraising_logs',
    }

    file { '/a/log/fundraising/logs/buffer':
        ensure  => directory,
        owner   => 'file_mover',
        group   => 'wikidev',
        mode    => '0750',
    }

    cron { 'rotate_fundraising_logs':
        ensure  => present,
        user    => 'file_mover',
        minute  => '*/15',
        command => '/usr/local/bin/rotate_fundraising_logs',
    }

    class { 'nfs::netapp::fr_archive':
        mountpoint => '/a/log/fundraising/logs/fr_archive',
    }

}
