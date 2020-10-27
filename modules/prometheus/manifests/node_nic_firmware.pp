# = Class: prometheus::node_nic_firmware
#
# Periodically export network interface device drivers & firmware versions.
#
# Intended to run on all physical hosts (not useful on e.g. Ganeti-hosted VMs).
#
class prometheus::node_nic_firmware (
    Wmflib::Ensure $ensure = 'present',
    Stdlib::Unixpath $outfile = '/var/lib/prometheus/node.d/nic_firmware.prom',
) {
    $exec = '/usr/local/bin/prometheus-nic-firmware'
    file { $exec:
        ensure => $ensure,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/prometheus/usr/local/bin/prometheus-nic-firmware.sh',
    }

    systemd::timer::job { 'prometheus-nic-firmware-textfile':
        ensure          => $ensure,
        description     => 'Update NIC firmware stats exported by node_exporter',
        command         => "${exec} ${outfile}",
        user            => 'root',
        logging_enabled => false,
        require         => [File[$exec]],
        interval        => {
            # We don't care about when this runs, as long as it runs every few minutes.
            # We also explicitly *don't* want to synchronize its execution across hosts,
            # as OnCalendar would do, and this should have some natural splay.
            'start'    => 'OnUnitInactiveSec',
            'interval' => '300s',
        },
    }
}
