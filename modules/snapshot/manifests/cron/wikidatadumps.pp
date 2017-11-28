class snapshot::cron::wikidatadumps(
    $user = undef,
    $group = undef,
) {
    class {'::snapshot::cron::wikidatadumps::common':
        user  => $user,
        group => $group,
    }
    class { '::snapshot::cron::wikidatadumps::json': user   => $user }
    class { '::snapshot::cron::wikidatadumps::rdf': user   => $user }
}
