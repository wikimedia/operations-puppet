class profile::openstack::base::pdns::auth::service(
    Array[Stdlib::Fqdn] $hosts = lookup('profile::openstack::base::pdns::hosts'),
    Array[Stdlib::Fqdn] $designate_hosts = lookup('profile::openstack::base::designate_hosts'),
    Array[Stdlib::IP::Address] $listen_on = lookup('profile::openstack::base::pdns::auth::listen_on'),
    Stdlib::Fqdn $default_soa_content = lookup('profile::openstack::base::pdns::default_soa_content'),
    Stdlib::Fqdn $query_local_address = lookup('profile::openstack::base::pdns::query_local_address'),
    $db_host = lookup('profile::openstack::base::pdns::db_host'),
    $db_pass = lookup('profile::openstack::base::pdns::db_pass'),
    $pdns_webserver = lookup('profile::openstack::base::pdns::pdns_webserver', {'default_value' => false}),
    String $pdns_api_key = lookup('profile::openstack::base::pdns::pdns_api_key', {'default_value' => ''}),
    $pdns_api_allow_from = lookup('profile::openstack::base::pdns::pdns_api_allow_from', {'default_value' => ''}),
){

    class { '::pdns_server':
        listen_on           => $listen_on,
        default_soa_content => $default_soa_content,
        query_local_address => $query_local_address,
        pdns_db_host        => $db_host,
        pdns_db_password    => $db_pass,
        dns_webserver       => $pdns_webserver,
        dns_api_key         => $pdns_api_key,
        dns_api_allow_from  => $pdns_api_allow_from,
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

    $api_clients = flatten([$hosts, $designate_hosts])
    ::ferm::service { 'pdns-rest-api':
        proto  => 'tcp',
        port   => '8081',
        srange => "@resolve((${join($api_clients,' ')}))",
    }
}
