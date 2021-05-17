# = Class: prometheus::node_sge
#
# Periodically export SGE stats via node-exporter textfile collector.
#
class prometheus::node_sge (
    Stdlib::Unixpath $outfile = '/var/lib/prometheus/node.d/sge.prom',
) {
    if $outfile !~ '\.prom$' {
        fail("outfile (${outfile}): Must have a .prom extension")
    }

    require_package('python3-prometheus-client')

    file { '/usr/local/bin/prometheus-sge-stats':
        ensure => file,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/prometheus/usr/local/bin/prometheus-sge-stats.py',
    }

    # Collect every minute
    systemd::timer::job { 'prometheus_sge_stats':
        ensure      => present,
        description => 'Regular job to collect SGE stats',
        user        => 'root',
        command     => "/usr/local/bin/prometheus-sge-stats --outfile ${outfile}",
        interval    => {'start' => 'OnCalendar', 'interval' => 'minutely'},
    }
}
