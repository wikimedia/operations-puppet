class snapshot::cron::contentxlation(
    $user      = undef,
    $filesonly = false,
) {
    $scriptpath = '/usr/local/bin/dumpcontentxlation.sh'
    file { $scriptpath:
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/snapshot/cron/dumpcontentxlation.sh',
    }

    if !$filesonly {
        cron { 'xlation-dumps':
            ensure      => absent,
            environment => 'MAILTO=ops-dumps@wikimedia.org',
            user        => $user,
            command     => '/usr/local/bin/dumpcontentxlation.sh',
            minute      => '10',
            hour        => '9',
            weekday     => '5',
            require     => File[$scriptpath],
        }
        systemd::timer::job { 'xlation-dumps':
            ensure             => present,
            description        => 'Regular jobs to build snapshot of content translation data',
            user               => $user,
            monitoring_enabled => false,
            send_mail          => true,
            environment        => {'MAILTO' => 'ops-dumps@wikimedia.org'},
            command            => '/usr/local/bin/dumpcontentxlation.sh',
            interval           => {'start' => 'OnCalendar', 'interval' => 'Fri *-*-* 9:10:0'},
            require            => File[$scriptpath],
        }
    }
}
