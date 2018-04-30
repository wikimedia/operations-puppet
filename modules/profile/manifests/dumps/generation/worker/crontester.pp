class profile::dumps::generation::worker::crontester {
    class { '::snapshot::cron':
        miscdumpsuser => 'dumpsgen',
        group         => 'www-data',
        filesonly     => true,
    }
}
