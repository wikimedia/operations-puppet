class role::snapshot::cron::secondary {
    include role::snapshot::common

    class { 'snapshot::addschanges':
        enable => false,
        user   => 'datasets',
    }
    class { 'snapshot::cron::mediadirlists':
        enable => false,
        user   => 'datasets',
    }
}

