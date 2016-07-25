class role::snapshot::cronjobs {
    include dataset::user
    class { '::snapshot::cron::mediaperprojectlists': user => 'datasets' }
    class { '::snapshot::cron::pagetitles': user   => 'datasets' }
    class { '::snapshot::cron::cirrussearch': user   => 'datasets' }
    class { '::snapshot::cron::centralauthdump': user   => 'datasets' }
    class { '::snapshot::cron::dumplists': user   => 'datasets' }
}
