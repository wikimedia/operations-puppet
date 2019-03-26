class profile::dumps::generation::worker::crontester(
    $php = hiera('profile::dumps::generation_worker_cron_php'),
) {
    class { '::snapshot::cron':
        miscdumpsuser => 'dumpsgen',
        group         => 'www-data',
        filesonly     => true,
        php           => $php,
    }
}
