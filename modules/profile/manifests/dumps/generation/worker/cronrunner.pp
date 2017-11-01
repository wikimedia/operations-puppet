class profile::dumps::generation::worker::cronrunner {
    class { '::snapshot::cron': user   => 'datasets' }
}
