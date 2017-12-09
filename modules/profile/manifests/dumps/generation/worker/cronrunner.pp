class profile::dumps::generation::worker::cronrunner {
    class { '::snapshot::cron':
        miscdumpsuser => 'dumpsgen',
        group         => 'www-data',
    }
}
