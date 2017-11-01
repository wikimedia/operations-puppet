class profile::dumps::generation::worker::monitor(
    $do_monitor = hiera('snapshot::dumps::monitor')
) {
    if $do_monitor {
        class { '::snapshot::dumps::monitor' }
    }
}
