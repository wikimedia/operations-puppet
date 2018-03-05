class profile::dumps::distribution::datasets::cleanup_miscdatasets(
    $miscdumpsdir = hiera('profile::dumps::distribution::miscdumpsdir'),
) {

    $user = 'dumpsgen'
    $cleanup_slowparse = "find ${miscdumpsdir}/slow-parse -type f -mtime +90 -exec rm {} \\;"

    cron { 'cleanup_miscdatasets':
        ensure      => 'present',
        environment => 'MAILTO=ops-dumps@wikimedia.org',
        command     => $cleanup_slowparse,
        user        => $user,
        minute      => '45',
        hour        => '1',
    }
}
