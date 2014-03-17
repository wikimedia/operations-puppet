class role::snapshot::common {
    include groups::wikidev

    include admins::roots
    include admins::mortals
    include accounts::datasets
    include sudo::appserver
}

class role::snapshot::cron::centralauthdump($enable=true) {
    include role::snapshot::common
    include snapshot::dirs

    file { '/usr/local/bin/dumpcentralauth.sh':
        mode    => '0755',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///files/misc/scripts/dumpcentralauth.sh',
    }

    # used by script to find the name of the correspondaing db.php file
    if ($::site == 'eqiad') {
        $dbsite = $::site
    }
    else {
        $dbsite = 'secondary'
    }

    if ($enable == true) {
        $ensure = 'present'
    }
    else {
        $ensure = 'absent'
    }

    system::role { 'role::snapshot::cron::centralauthdump':
        ensure      => $ensure,
        description => 'mysql dumper of centralauth',
    }

    cron { 'centralauth-dump':
        ensure      => $ensure,
        command     => "/usr/local/bin/dumpcentralauth.sh --site ${dbsite} --config ${snapshot::dirs::dumpsdir}/confs/wikidump.conf",
        environment => 'MAILTO=ops-dumps@wikimedia.org',
        user        => datasets,
        minute      => '15',
        hour        => '8',
        weekday     => '6',
        require     => [File['/usr/local/bin/dumpcentralauth.sh'],
                       User['datasets']],
    }
}

class role::snapshot::cron::primary {
    class { 'role::snapshot::cron::centralauthdump':
        enable => true,
    }
    class { 'snapshot::dumps::pagetitles':
        # can't enable yet
        enable => false,
        user   => 'datasets',
    }
}

class role::snapshot::cron::secondary {
    class { 'role::snapshot::cron::centralauthdump':
        enable => false,
    }
    class { 'snapshot::dumps::pagetitles':
        enable => false,
        user   => 'datasets',
    }
}
