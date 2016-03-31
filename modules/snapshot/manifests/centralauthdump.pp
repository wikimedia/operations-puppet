class snapshot::centralauthdump(
    $enable = true,
    $user   = undef,
) {
    include snapshot::dumps::dirs

    if ($enable == true) {
        $ensure = 'present'
    }
    else {
        $ensure = 'absent'
    }

    file { '/usr/local/bin/dumpcentralauth.sh':
        mode    => '0755',
        owner   => 'root',
        group   => 'root',
        content => templates('snapshot/dumpcentralauth.sh.erb'),
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
        command     => "/usr/local/bin/dumpcentralauth.sh --site ${dbsite} --config ${snapshot::dumps::dirs::dumpsdir}/confs/wikidump.conf",
        environment => 'MAILTO=ops-dumps@wikimedia.org',
        user        => $user,
        minute      => '15',
        hour        => '8',
        weekday     => '6',
    }
}
