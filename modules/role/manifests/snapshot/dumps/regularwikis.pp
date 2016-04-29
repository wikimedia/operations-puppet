class role::snapshot::dumps::regularwikis {
    include role::snapshot::common
    class { 'snapshot::dumps::cron::rest':
        user   => 'datasets',
    }
}

