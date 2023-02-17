# SPDX-License-Identifier: Apache-2.0
class profile::openstack::base::pdns::auth::service(
    Array[Hash] $hosts = lookup('profile::openstack::base::pdns::hosts'),
    Array[Stdlib::Fqdn] $designate_hosts = lookup('profile::openstack::base::designate_hosts'),
    Stdlib::Fqdn $default_soa_content = lookup('profile::openstack::base::pdns::default_soa_content'),
    $db_host = lookup('profile::openstack::base::pdns::db_host'),
    $db_pass = lookup('profile::openstack::base::pdns::db_pass'),
    Array[Stdlib::Fqdn] $prometheus_nodes = lookup('prometheus_nodes'),
    String $pdns_api_key = lookup('profile::openstack::base::pdns::pdns_api_key', {'default_value' => ''}),
){
    $this_host_entry = ($hosts.filter | $host | {$host['host_fqdn'] == $::fqdn})[0]
    $dns_webserver_address = $this_host_entry['private_fqdn'].ipresolve(4)
    $listen_on = [$this_host_entry['auth_fqdn'].ipresolve(4)]
    $query_local_address = $this_host_entry['auth_fqdn']

    $pdns_auth_hosts = $hosts.map |$host| { $host['auth_fqdn'] }
    $pdns_api_allow_from = [$pdns_auth_hosts, $designate_hosts, $prometheus_nodes].flatten.map |Stdlib::Fqdn $fqdn| {
        dnsquery::a($fqdn)
    }.flatten + ['127.0.0.1']

    class { '::pdns_server':
        listen_on             => $listen_on,
        default_soa_content   => $default_soa_content,
        query_local_address   => $query_local_address,
        pdns_db_host          => $db_host,
        pdns_db_password      => $db_pass,
        dns_webserver_address => '0.0.0.0',
        dns_api_key           => $pdns_api_key,
        dns_api_allow_from    => $pdns_api_allow_from.sort,
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

    ferm::service { 'pdns-rest-api':
        proto  => 'tcp',
        port   => '8081',
        srange => [$pdns_auth_hosts + $designate_hosts].flatten,
        drange => $dns_webserver_address,
    }
}
