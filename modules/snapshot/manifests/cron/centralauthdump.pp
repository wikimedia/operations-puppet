class snapshot::cron::centralauthdump(
    $user   = undef,
) {
    include ::snapshot::dumps::dirs
    $confsdir = $snapshot::dumps::dirs::confsdir

    file { '/usr/local/bin/dumpcentralauth.sh':
        mode    => '0755',
        owner   => 'root',
        group   => 'root',
        content => template('snapshot/cron/dumpcentralauth.sh.erb'),
    }

    # used by script to find the name of the corresponding db.php file
    if ($::site == 'eqiad') {
        $dbsite = $::site
    }
    else {
        $dbsite = 'secondary'
    }

    cron { 'centralauth-dump':
        ensure      => 'present',
        command     => "/usr/local/bin/dumpcentralauth.sh --site ${dbsite} --config ${confsdir}/wikidump.conf",
        environment => 'MAILTO=ops-dumps@wikimedia.org',
        user        => $user,
        minute      => '15',
        hour        => '8',
        weekday     => '6',
    }
}
