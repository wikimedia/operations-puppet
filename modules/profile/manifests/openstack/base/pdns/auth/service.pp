class profile::openstack::base::pdns::auth::service(
    $host = hiera('profile::openstack::base::pdns::host'),
    $host_secondary = hiera('profile::openstack::base::pdns::host_secondary'),
    $db_host = hiera('profile::openstack::base::pdns::db_host'),
    $db_pass = hiera('profile::openstack::base::pdns::db_pass'),
    $pdns_webserver = hiera('profile::openstack::base::pdns::pdns_webserver', false),
    $pdns_api_key = hiera('profile::openstack::base::pdns::pdns_api_key', ''),
    ) {

    class { '::pdns_server':
        dns_auth_ipaddress     => $facts['ipaddress'],
        dns_auth_ipaddress6    => $facts['ipaddress6'],
        dns_auth_query_address => $facts['ipaddress'],
        dns_auth_soa_name      => $host,
        pdns_db_host           => $db_host,
        pdns_db_password       => $db_pass,
        dns_webserver          => $pdns_webserver,
        dns_api_key            => $pdns_api_key,
    }

    ferm::service { 'udp_dns_rec':
        proto => 'udp',
        port  => '53',
    }

    ferm::service { 'tcp_dns_rec':
        proto => 'tcp',
        port  => '53',
    }

    ferm::rule { 'skip_dns_conntrack-out':
        desc  => 'Skip DNS outgoing connection tracking',
        table => 'raw',
        chain => 'OUTPUT',
        rule  => 'proto udp sport 53 NOTRACK;',
    }

    ferm::rule { 'skip_dns_conntrack-in':
        desc  => 'Skip DNS incoming connection tracking',
        table => 'raw',
        chain => 'PREROUTING',
        rule  => 'proto udp dport 53 NOTRACK;',
    }

    ::ferm::service { 'pdns-rest-api':
        proto  => 'tcp',
        port   => '8081',
        srange => "(@resolve((${host} ${host_secondary})) @resolve((${host} ${host_secondary}), AAAA))",
    }
}
