# == class prometheus::nic_saturation_exporter
#
# Deploys an exporter that polls network interface transmit/receive byte
# counters every second, and increments counters whenever utilization was
# too high in a one-second window.  Catches micro-bursts of saturation that
# escape detection by normal monitoring (which has a 30-second window).
class prometheus::nic_saturation_exporter(
    Wmflib::Ensure         $ensure         = 'present',
    Optional[Stdlib::Host] $listen_address = undef,
) {
    ensure_packages(['python3-prometheus-client'])

    $script_path = '/usr/local/bin/prometheus-nic-saturation-exporter'

    file { $script_path:
        ensure => $ensure,
        source => 'puppet:///modules/prometheus/usr/local/bin/prometheus-nic-saturation-exporter.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    $service_name = 'nic-saturation-exporter'
    systemd::service { $service_name:
        ensure    => $ensure,
        content   => systemd_template('prometheus-nic-saturation-exporter'),
        restart   => true,
        subscribe => File[$script_path],
        # For the prometheus user
        require   => Package['prometheus-node-exporter'],
    }

    profile::auto_restarts::service { $service_name:
        ensure => $ensure,
    }
}
