# = Class: prometheus::node_intel_microcode
#
# Periodically export intel_microcode version information via node-exporter
# textfile collector.

class prometheus::node_intel_microcode (
    Wmflib::Ensure     $ensure  = 'present',
    Pattern[/\.prom$/] $outfile = '/var/lib/prometheus/node.d/intel_microcode.prom',
) {
    ensure_packages(['iucode-tool'])

    file { '/usr/local/bin/prometheus-intel-microcode':
        ensure  => file,
        mode    => '0555',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///modules/prometheus/usr/local/bin/prometheus-intel-microcode',
        require => Package['iucode-tool'],
    }

    # Collect every hour
    cron { 'prometheus_intel_microcode':
        ensure => 'absent',
    }
    systemd::timer::job { 'prometheus_intel_microcode':
        ensure      => $ensure,
        user        => 'root',
        description => 'Intel microcode prometheus metrics exporter',
        command     => "/usr/local/bin/prometheus-intel-microcode ${outfile}",
        interval    => {'start' => 'OnUnitInactiveSec', 'interval' => '1h'},
        require     => File['/usr/local/bin/prometheus-intel-microcode'],
    }
}
