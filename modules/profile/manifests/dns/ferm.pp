# DNS Server (of any kind) ferm rules
class profile::dns::ferm {
    include ::profile::base::firewall

    ferm::service { 'udp_dns_server':
        proto   => 'udp',
        notrack => true,
        port    => '53',
    }

    ferm::service { 'tcp_dns_server':
        proto => 'tcp',
        port  => '53',
    }
}
