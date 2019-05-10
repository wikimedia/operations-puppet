# = Class: prometheus::node_vhtcpd
#
# Periodically export vhtcpd stats via node-exporter textfile collector.
#
# Why not a vhtcpd_exporter?
#
# vhtcpd is very specific to WMF's deployment and there's only one instance per
# server. We can consider vhtcp statistics to be "machine-level", thus it is
# simpler to use Prometheus Python client and its write_to_textfile function to
# write metrics in a plain text file to be exported by node-exporter
#

class prometheus::node_vhtcpd (
    $outfile = '/var/lib/prometheus/node.d/vhtcpd.prom',
) {
    validate_re($outfile, '\.prom$')

    require_package('python-prometheus-client')

    file { '/usr/local/bin/prometheus-vhtcpd-stats':
        ensure => file,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/prometheus/usr/local/bin/prometheus-vhtcpd-stats.py',
    }

    # Collect every minute
    cron { 'prometheus_vhtcpd_stats':
        user    => 'root',
        command => "systemctl is-active -q vhtcpd && test -s /tmp/vhtcpd.stats && /usr/local/bin/prometheus-vhtcpd-stats --outfile ${outfile}",
    }
}
