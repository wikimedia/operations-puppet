# = Class: prometheus::node_local_crontabs
#
# Export local crontab information via node-exporter textfile collector.
class prometheus::node_local_crontabs (
    Wmflib::Ensure $ensure = 'present',
) {
    file { '/usr/local/bin/prometheus-local-crontabs':
        ensure => $ensure,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/prometheus/usr/local/bin/prometheus-local-crontabs.sh',
    }

}

