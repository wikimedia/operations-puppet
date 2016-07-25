class role::snapshot::cronjobs {
    include dataset::user
    class { '::snapshot::cron::mediaperprojectlists': user => 'datasets' }
    class { '::snapshot::cron::pagetitles': user   => 'datasets' }
    class { '::snapshot::cron::cirrussearch': user   => 'datasets' }
}
