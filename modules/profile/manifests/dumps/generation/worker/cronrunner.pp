class profile::dumps::generation::worker::cronrunner(
    $do_crons = hiera('snapshot::cron::misc'),
) {
    if $do_crons {
        class { '::snapshot::cron': user   => 'datasets' }
    }
}
