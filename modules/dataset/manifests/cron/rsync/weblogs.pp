class dataset::cron::rsync::weblogs($enable=true) {
    $source = '/var/log/nginx/',
    $enable = true,
    $dest   = undef,
    $user   = 'root',
)
{
    include dataset::common

    if ($enable) {
        $ensure = 'present'
    }
    else {
        $ensure = 'absent'
    }

    $rsync_args = '-rt --delete --bwlimit=50000'
    if ($enable) {
        cron { 'weblogs_stat1002_rsync':
            ensure      => $ensure,
            user        => $user,
            minute      => '50',
            hour        => '4',
            command     => "/usr/bin/rsync ${rsync_args} ${source}/ ${dest}/",
            environment => 'MAILTO=ops-dumps@wikimedia.org',
            require     => User[$user],
        }
    }
    else {
        cron { 'weblogs_stat1002_rsync':
            ensure      => absent,
        }
    }
}

