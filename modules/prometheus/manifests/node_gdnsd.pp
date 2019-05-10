# = Class: prometheus::node_gdnsd
#
# Periodically export gdnsd stats via node-exporter textfile collector.
#
# Why not a gdnsd_exporter?
#
# In WMF's case there aren't a lot of machines with gdnsd deployed as of Dec 2016.
# Also, having an exporter would have the added benefit of being able to
# aggregate stats on other dimensions rather than per-cluster or per-site.

class prometheus::node_gdnsd (
    $ensure = 'present',
    $outfile = '/var/lib/prometheus/node.d/gdnsd.prom',
) {
    validate_re($outfile, '\.prom$')
    validate_ensure($ensure)

    require_package( [
        'python-prometheus-client',
        'python-requests',
    ] )

    file { '/usr/local/bin/prometheus-gdnsd-stats':
        ensure => file,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/prometheus/usr/local/bin/prometheus-gdnsd-stats.py',
    }

    # Collect every minute
    cron { 'prometheus_gdnsd_stats':
        ensure  => $ensure,
        user    => 'root',
        command => "/usr/local/bin/prometheus-gdnsd-stats --outfile ${outfile}",
    }
}
