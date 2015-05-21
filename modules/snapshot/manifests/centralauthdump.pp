class snapshot::centralauthdump(
    $enable = true,
    $user   = undef,
) {
    include snapshot::dirs

    if ($enable == true) {
        $ensure = 'present'
    }
    else {
        $ensure = 'absent'
    }

    system::role { 'snapshot::centralauthdump':
        ensure      => $ensure,
        description => 'mysql dumper of centralauth',
    }

    file { '/usr/local/bin/dumpcentralauth.sh':
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/snapshot/dumpcentralauth.sh',
    }

    # used by script to find the name of the corresponding db.php file
    if ($::site == 'eqiad') {
        $dbsite = $::site
    }
    else {
        $dbsite = 'secondary'
    }

    cron { 'centralauth-dump':
        ensure      => $ensure,
        command     => "/usr/local/bin/dumpcentralauth.sh --site ${dbsite} --config ${snapshot::dirs::dumpsdir}/confs/wikidump.conf",
        environment => 'MAILTO=ops-dumps@wikimedia.org',
        user        => $user,
        minute      => '15',
        hour        => '8',
        weekday     => '6',
    }
}
