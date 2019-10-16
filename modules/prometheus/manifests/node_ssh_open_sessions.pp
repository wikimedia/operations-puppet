# = Class: prometheus::node_ssh_open_sessions
#
# Periodically export active shell session information via node-exporter
# textfile collector.

class prometheus::node_ssh_open_sessions (
    Wmflib::Ensure $ensure = 'present',
    Pattern[/\.prom$/] $outfile = '/var/lib/prometheus/node.d/ssh_open_sessions.prom',
) {
    file { '/usr/local/bin/prometheus-ssh_open_sessions':
        ensure => file,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/prometheus/usr/local/bin/prometheus-ssh_open_sessions',
    }

    # Collect every 5 minutes
    cron { 'prometheus_ssh_open_sessions':
        ensure  => $ensure,
        user    => 'root',
        minute  => '*/5',
        command => "/usr/local/bin/prometheus-ssh_open_sessions ${outfile}",
    }
}

