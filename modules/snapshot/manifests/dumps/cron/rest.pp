class snapshot::dumps::cron::rest(
    $enable = true,
    $user   = undef,
) {
    include snapshot::dumps::dirs
    include snapshot::dumps::cron

    # fixme there is an implicit dependency on
    # $dumpsdir/confs/wikidump.conf.* plus some stage files, make explicit
    cron { 'fulldumps_rest':
        ensure      => 'present',
        environment => 'MAILTO=ops-dumps@wikimedia.org',
        user        => $user,
        command     => "/usr/local/bin/fulldumps.sh 01 14 regular > /dev/null",
        minute      => '05',
        hour        => '02',
        monthday    => '01-14',
    }
}
