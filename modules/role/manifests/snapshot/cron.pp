class role::snapshot::cron {
    include ::dataset::user
    class { 'snapshot::dumps::cron': user => 'datasets' }
}
