# = Class: prometheus::node_puppet_agent
#
# Periodically export puppet agent stats via node-exporter textfile collector.
#

class prometheus::node_puppet_agent (
    Wmflib::Ensure $ensure = 'present',
    Stdlib::AbsolutePath $outfile = '/var/lib/prometheus/node.d/puppet_agent.prom',
) {
    if !($outfile =~ /\.prom$/) {
        fail("\$outfile should end with '.prom' but is [${outfile}]")
    }

    require_package(['python-prometheus-client', 'python-yaml'])

    file { '/usr/local/bin/prometheus-puppet-agent-stats':
        ensure => file,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/prometheus/usr/local/bin/prometheus-puppet-agent-stats.py',
    }

    # Collect every minute
    cron { 'prometheus_puppet_agent_stats':
        ensure  => $ensure,
        user    => 'prometheus',
        command => "/usr/local/bin/prometheus-puppet-agent-stats --outfile ${outfile}",
        require => Package['prometheus-node-exporter'],
    }
}
