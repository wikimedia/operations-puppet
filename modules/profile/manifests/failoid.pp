class profile::failoid (
    $tcp_rejected_ports = hiera('failoid::tcp_rejected_ports'),
) {
    validate_array($tcp_rejected_ports)

    if ! empty($tcp_rejected_ports) {
        $tcp_dports = join($tcp_rejected_ports, ' ')
        ferm::rule { 'failoid-rejected':
            rule => "proto tcp dport (${tcp_dports}) REJECT;",
        }
    }
}
