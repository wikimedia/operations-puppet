# = Class: prometheus::node_varnishd_mmap_count
#
# Periodically export the number of varnishd memory map areas to node-exporter
# textfile collector.

class prometheus::node_varnishd_mmap_count (
    Wmflib::Ensure $ensure = 'present',
    Pattern[/\.prom$/] $outfile = '/var/lib/prometheus/node.d/varnishd_mmap_count.prom',
    Systemd::Servicename $service = 'varnish.service',
) {
    file { '/usr/local/bin/prometheus-varnishd_mmap_count':
        ensure => file,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/prometheus/usr/local/bin/prometheus-varnishd_mmap_count',
    }

    # Collect every minute
    cron { 'prometheus_varnishd_mmap_count':
        ensure  => $ensure,
        user    => 'root',
        command => "/usr/local/bin/prometheus-varnishd_mmap_count ${service} ${outfile}",
    }
}

