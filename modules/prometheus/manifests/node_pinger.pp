#
# Simple latency statistics pinging a different nodes
#
class prometheus::node_pinger (
    Array[Stdlib::Fqdn] $nodes_to_ping = [],
    Wmflib::Ensure $ensure  = 'present',
    Stdlib::Unixpath $outfile = '/var/lib/prometheus/node.d/node_pinger.prom',
) {
    $script = '/usr/local/bin/prometheus-node-pinger'
    file { $script:
        ensure => $ensure,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/prometheus/usr/local/bin/prometheus_node_pinger.sh',
    }
    if !empty($nodes_to_ping) {
        systemd::timer::job { 'prometheus-node-pinger':
            ensure         => $ensure,
            user           => 'root',
            description    => 'Generate prometheus network latency metrics with pings',
            command        => "${script} ${nodes_to_ping.join(' ')}",
            stdout         => "file:${outfile}",
            exec_start_pre => "/usr/bin/rm -f ${outfile}",
            interval       => {
                'start'    => 'OnCalendar',
                'interval' => 'minutely',
            },
            require        => [File[$script], Class['prometheus::node_exporter'],]
        }
    }
}
