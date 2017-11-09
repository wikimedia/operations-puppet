class profile::dumps::generation::worker::cronrunner {
    class { '::snapshot::cron':
        depr_user     => 'datasets',
        miscdumpsuser => 'dumpsgen',
        group         => 'www-data',
    }
}
