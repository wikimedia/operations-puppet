# = Class: prometheus::node_amd_rocm
#
# Periodically export AMD ROCm GPU stats via node-exporter textfile collector.
#
# Why not a node_amd_rocm exporter?
#
# In WMF's case there aren't a lot of machines with a GPU deployed, and the
# number of metrics to collect are really few.
#
class prometheus::node_amd_rocm (
    $ensure = 'present',
    $outfile = '/var/lib/prometheus/node.d/rocm.prom',
) {
    validate_re($outfile, '\.prom$')
    validate_ensure($ensure)

    require_package( [
        'python-prometheus-client',
        'python-requests',
    ] )

    file { '/usr/local/bin/prometheus-amd-rocm-stats':
        ensure => file,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/prometheus/usr/local/bin/prometheus-amd-rocm-stats.py',
    }

    # Collect every minute
    cron { 'prometheus_amd_rocm_stats':
        ensure  => $ensure,
        user    => 'root',
        command => "/usr/local/bin/prometheus-amd-rocm-stats --outfile ${outfile}",
    }
}
