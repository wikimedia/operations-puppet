# = Class: prometheus::node_intel_microcode
#
# Periodically export intel_microcode version information via node-exporter
# textfile collector.

class prometheus::node_intel_microcode (
    Wmflib::Ensure $ensure = 'present',
    Pattern[/\.prom$/] $outfile = '/var/lib/prometheus/node.d/intel_microcode.prom',
) {
    require_package('iucode-tool')

    file { '/usr/local/bin/prometheus-intel-microcode':
        ensure => file,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/prometheus/usr/local/bin/prometheus-intel-microcode',
    }

    # Collect every hour
    cron { 'prometheus_intel_microcode':
        ensure  => $ensure,
        user    => 'root',
        minute  => '42',
        command => "/usr/local/bin/prometheus-intel-microcode ${outfile}",
    }
}
