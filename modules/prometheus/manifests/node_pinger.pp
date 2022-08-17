#
# Simple latency statistics pinging a different nodes
#
class prometheus::node_pinger (
    Hash[Stdlib::Fqdn, Stdlib::IP::Address::Nosubnet] $nodes_to_ping_regular_mtu = {},
    Hash[Stdlib::Fqdn, Stdlib::IP::Address::Nosubnet] $nodes_to_ping_jumbo_mtu = {},
    Wmflib::Ensure $ensure  = 'present',
    Stdlib::Unixpath $outfile = '/var/lib/prometheus/node.d/node_pinger.prom',
) {
    $script = '/usr/local/bin/prometheus-node-pinger'
    file { $script:
        ensure  => $ensure,
        mode    => '0555',
        owner   => 'root',
        group   => 'root',
        content => epp(
            'prometheus/usr/local/bin/prometheus_node_pinger.sh',
            {
                nodes_to_ping_regular_mtu => $nodes_to_ping_regular_mtu,
                nodes_to_ping_jumbo_mtu   => $nodes_to_ping_jumbo_mtu,
            },
        ),
    }
    if !empty($nodes_to_ping_jumbo_mtu + $nodes_to_ping_regular_mtu) {
        systemd::timer::job { 'prometheus-node-pinger':
            ensure         => $ensure,
            user           => 'root',
            description    => 'Generate prometheus network latency metrics with pings',
            command        => $script,
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
