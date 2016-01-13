class snapshot::dumps::cron::rest(
    $enable = true,
    $user   = undef,
) {
    include snapshot::dirs
    include snapshot::dumps::cron
  
    # fixme there is an implicit dependency on
    # $dumpsdir/confs/wikidump.conf.* plus some stage files, make explicit
    cron { 'fulldumps_rest':
        # not ready yet
        ensure      => 'absent',
        environment => 'MAILTO=ops-dumps@wikimedia.org',
        user        => $user,
        command     => '/srv/dumps/fulldumps.sh 01 14 "bigwikis smallwikis"',
        minute      => '05',
        hour        => '02',
        monthday    => '01-14',
    }
}
