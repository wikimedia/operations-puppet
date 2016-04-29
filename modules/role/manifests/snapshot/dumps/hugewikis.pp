class role::snapshot::dumps::hugewikis {
    include role::snapshot::common
    class { 'snapshot::dumps::cron::huge':
        user   => 'datasets',
    }
}

