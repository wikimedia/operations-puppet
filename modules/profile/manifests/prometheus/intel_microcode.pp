# = Class: profile::prometheus::intel_microcode
#
# Periodically export intel_microcode version information via node-exporter
# textfile collector.

class profile::prometheus::intel_microcode (
    $ensure = 'present',
    $outfile = '/var/lib/prometheus/node.d/intel_microcode.prom',
) {
    validate_re($outfile, '\.prom$')
    validate_ensure($ensure)

    require_package('iucode-tool')

    file { '/usr/local/bin/prometheus-intel-microcode':
        ensure => file,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/profile/prometheus/prometheus-intel-microcode',
    }

    # Collect every hour
    cron { 'prometheus_intel_microcode':
        ensure  => $ensure,
        user    => 'root',
        minute  => '42',
        command => "/usr/local/bin/prometheus-intel-microcode ${outfile}",
    }
}
