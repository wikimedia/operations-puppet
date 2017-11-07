class dumps::cron::wikidatadumps(
    $user = undef,
    $group = undef,
) {
    class {'::dumps::cron::wikidatadumps::common':
        user => $user,
        group => $group,
    }
    class { '::snapshot::cron::wikidatadumps::json': user   => $user }
    class { '::snapshot::cron::wikidatadumps::rdf': user   => $user }
}
