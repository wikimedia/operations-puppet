class snapshot::cron(
    $user = undef,
) {
    class { '::snapshot::cron::mediaperprojectlists': user => $user }
    class { '::snapshot::cron::pagetitles': user   => $user }
    class { '::snapshot::cron::cirrussearch': user   => $user }
    class { '::snapshot::cron::dumplists': user   => $user }
    class { '::snapshot::cron::wikidatadumps::json': user   => $user }
    class { '::snapshot::cron::wikidatadumps::ttl': user   => $user }
    class { '::snapshot::cron::contentxlation': user   => $user }
    class { '::snapshot::addschanges': user   => $user }
}
