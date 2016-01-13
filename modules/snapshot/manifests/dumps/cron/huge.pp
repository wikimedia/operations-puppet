class snapshot::dumps::cron::huge(
    $enable = true,
    $user   = undef,
) {
    include snapshot::dirs
    include snapshot::dumps::cron

    # fixme there is an implicit dependency on
    # $dumpsdir/confs/wikidump.conf.* plus some stage files, make explicit
    cron { 'fulldumps_huge':
        # not ready yet
        ensure      => 'absent',
        environment => 'MAILTO=ops-dumps@wikimedia.org',
        user        => $user,
        command     => "pgrep fulldumps.sh && ${snapshot::dirs::dumpsdir}/fulldumps.sh 01 14 hugewikis",
        minute      => '05',
        hour        => '02',
        monthday    => '01-14',
    }
}
