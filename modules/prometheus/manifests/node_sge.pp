# = Class: prometheus::node_sge
#
# Periodically export SGE stats via node-exporter textfile collector.
#
class prometheus::node_sge (
    $outfile = '/var/lib/prometheus/node.d/sge.prom',
) {
    validate_re($outfile, '\.prom$')

    require_package('python3-prometheus-client')

    file { '/usr/local/bin/prometheus-sge-stats':
        ensure => file,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/prometheus/usr/local/bin/prometheus-sge-stats.py',
    }

    # Collect every minute
    cron { 'prometheus_sge_stats':
        user    => 'root',
        command => "/usr/local/bin/prometheus-sge-stats --outfile ${outfile}",
    }
}
