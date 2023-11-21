# = Class: prometheus::node_puppet_agent
#
# Periodically export puppet agent stats via node-exporter textfile collector.
#

class prometheus::node_puppet_agent (
    Wmflib::Ensure       $ensure  = 'present',
    Stdlib::AbsolutePath $outfile = '/var/lib/prometheus/node.d/puppet_agent.prom',
    Boolean              $debug   = false,
) {
    if !($outfile =~ /\.prom$/) {
        fail("\$outfile should end with '.prom' but is [${outfile}]")
    }

    ensure_packages(['python3-prometheus-client', 'python3-yaml'])

    file { '/usr/local/bin/prometheus-puppet-agent-stats':
        ensure => file,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/prometheus/usr/local/bin/prometheus-puppet-agent-stats.py',
    }

    # Collect every minute
    systemd::timer::job { 'prometheus_puppet_agent_stats':
        ensure      => absent,
        description => 'Regular job to collect puppet agent stats',
        user        => 'root',
        interval    => {'start' => 'OnCalendar', 'interval' => 'minutely'},
        command     => "/usr/local/bin/prometheus-puppet-agent-stats --outfile ${outfile}",
        after       => 'puppet-agent-timer.service',
        require     => File[$outfile.dirname]
    }

    # Use systemd::unit in place of systemd::service since we need to
    # drop the unit only and *not* make sure it is running.
    # Doing so would get puppet stuck since this unit requires a puppet
    # run to be complete (After=puppet-agent-timer.service)
    systemd::unit { 'prometheus-puppet-agent-stats':
        ensure  => $ensure,
        content => init_template('prometheus-puppet-agent-stats', 'systemd'),
        require => File[$outfile.dirname],
    }

    # Need to enable the service since we're using WantedBy=puppet-agent-timer.service
    exec { 'enable prometheus-puppet-agent-stats':
        command => '/bin/systemctl enable prometheus-puppet-agent-stats',
        unless  => '/bin/systemctl -q is-enabled prometheus-puppet-agent-stats',
        require => Systemd::Unit['prometheus-puppet-agent-stats'],
    }

}
