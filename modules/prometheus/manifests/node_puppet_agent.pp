# = Class: prometheus::node_puppet_agent
#
# Periodically export puppet agent stats via node-exporter textfile collector.
#

class prometheus::node_puppet_agent (
    $ensure = 'present',
    $outfile = '/var/lib/prometheus/node.d/puppet_agent.prom',
) {
    validate_re($outfile, '\.prom$')
    validate_ensure($ensure)

    require_package(['python-prometheus-client', 'python-yaml'])

    file { '/usr/local/bin/prometheus-puppet-agent-stats':
        ensure => file,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/prometheus/usr/local/bin/prometheus-puppet-agent-stats',
    }

    # Collect every minute
    cron { 'prometheus_puppet_agent_stats':
        ensure  => $ensure,
        user    => 'prometheus',
        command => "/usr/local/bin/prometheus-puppet-agent-stats --outfile ${outfile}",
    }
}
