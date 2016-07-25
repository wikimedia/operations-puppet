class role::snapshot::cronjobs {
    include dataset::user
    class { '::snapshot::cron::mediaperprojectlists': user => 'datasets' }
    class { '::snapshot::cron::pagetitles': user   => 'datasets' }
    class { '::snapshot::cron::cirrussearch': user   => 'datasets' }
    class { '::snapshot::cron::centralauthdump': user   => 'datasets' }
    class { '::snapshot::cron::dumplists': user   => 'datasets' }
    class { '::snapshot::cron::wikidatadumps::json': user   => 'datasets' }
    class { '::snapshot::cron::wikidatadumps::ttl': user   => 'datasets' }
    class { '::snapshot::addschanges': user   => 'datasets' }
}
