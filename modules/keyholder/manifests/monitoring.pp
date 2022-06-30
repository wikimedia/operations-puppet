# == Class: keyholder::monitoring
#
# Provisions a Prometheus node.d collector that
# ensures the keyholder is armed with all configured identities.
#
class keyholder::monitoring(
    Wmflib::Ensure $ensure = present,
) {
    file { '/usr/local/sbin/prometheus-keyholder-exporter':
        ensure => $ensure,
        source => 'puppet:///modules/keyholder/prometheus-keyholder-exporter.sh',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    systemd::timer::job { 'prometheus-keyholder-exporter':
        ensure      => $ensure,
        description => 'Regular job to collect Keyholder armed state as Prometheus metrics',
        user        => 'root',
        command     => '/usr/local/sbin/prometheus-keyholder-exporter',
        interval    => {'start' => 'OnCalendar', 'interval' => 'minutely'},
    }
}
