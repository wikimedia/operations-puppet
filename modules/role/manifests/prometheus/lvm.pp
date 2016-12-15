class role::prometheus::lvm {

    include ::lvm
    $prometheus_dir = '/srv/prometheus'

    lvm::logical_volume { 'prometheus-ops':
        ensure       => $ensure,
        volume_group => 'vg-ssd',
        size         => '200G',
        mountpath    => "${prometheus_dir}/ops",
    }

    lvm::logical_volume { 'prometheus-global:
        ensure       => $ensure,
        volume_group => 'vg-hdd',
        size         => '300G',
        mountpath    => "${prometheus_dir}/global",
    }
}
