# == class prometheus::mini_textfile_exporter
#
# The exporter is intended to be used for "info style" metrics written on
# the filesystem in "textfile" Prometheus format.
#
# It is similar to the textfile collector in node-exporter, however the
# intended use case is to be able to use "honor_labels: true" in Prometheus and
# therefore allow users to use arbitrarily-named metrics.

class prometheus::mini_textfile_exporter(
    Wmflib::Ensure $ensure = 'present',
    String         $glob   = '/var/lib/prometheus/mini-textfile.d/*.prom',
) {
    ensure_packages(['python3-prometheus-client'])

    $script_path = '/usr/local/bin/prometheus-mini-textfile-exporter'

    file { dirname($glob):
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    file { $script_path:
        ensure => $ensure,
        source => 'puppet:///modules/prometheus/usr/local/bin/prometheus-mini-textfile-exporter.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    $service_name = 'mini-textfile-exporter'
    systemd::service { $service_name:
        ensure    => $ensure,
        content   => systemd_template('prometheus-mini-textfile-exporter'),
        restart   => true,
        subscribe => File[$script_path],
    }

    profile::auto_restarts::service { $service_name:
        ensure => $ensure,
    }
}
