class role::snapshot::cron::primary {
    include role::snapshot::common

    class { 'snapshot::addschanges':
        enable => true,
        user   => 'datasets',
    }
}

