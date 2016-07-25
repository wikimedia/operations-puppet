class role::snapshot::cronjobs {
    include dataset::user
    class { '::snapshot::cron::mediaperprojectlists': user => 'datasets' }
}
