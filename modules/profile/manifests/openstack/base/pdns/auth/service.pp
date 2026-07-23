# SPDX-License-Identifier: Apache-2.0
class profile::openstack::base::pdns::auth::service(
    Array[Profile::Openstack::Pdns::Host] $hosts = lookup('profile::openstack::base::pdns::hosts'),
    Array[Stdlib::Fqdn] $designate_hosts = lookup('profile::openstack::base::designate_hosts'),
    Stdlib::Fqdn $default_soa_content = lookup('profile::openstack::base::pdns::default_soa_content'),
    $db_host = lookup('profile::openstack::base::pdns::db_host'),
    $db_pass = lookup('profile::openstack::base::pdns::db_pass'),
    Array[Stdlib::Fqdn] $prometheus_nodes = lookup('prometheus_nodes'),
    String $pdns_api_key = lookup('profile::openstack::base::pdns::pdns_api_key', {'default_value' => ''}),
) {
    $this_host_entry = ($hosts.filter | $host | {$host['host_fqdn'] == $facts['networking']['fqdn']})[0]
    $dns_webserver_allow_to = dnsquery::lookup($this_host_entry['private_fqdn'], true)
    $auth_ips = $this_host_entry['auth_ips']

    $pdns_auth_hosts = $hosts.map |$host| { $host['auth_ips'] }.flatten
    $pdns_api_allow_from = [
        $pdns_auth_hosts,
        $designate_hosts,
        $prometheus_nodes,
        '127.0.0.1', '::1',
    ]
        .flatten
        .wmflib::hosts2ips()
        .map |Stdlib::IP::Address::Nosubnet $ip| {
            $ip ? {
                # When the web server is bound on all IPv6 interfaces (::),
                # it will see v4 addresses using the IPv6 compat form instead of
                # the normal v4 form. We add both forms to the ACL here, since the same
                # list is used for allow-axfr-ips which does see the normal v4 addresses.
                Stdlib::IP::Address::V4::Nosubnet => [$ip, "::ffff:${ip}"],
                default                           => $ip,
            }
        }
        .flatten
        .sort

    class { '::pdns_server':
        listen_on             => $auth_ips,
        default_soa_content   => $default_soa_content,
        query_local_address   => $auth_ips,
        pdns_db_host          => $db_host,
        pdns_db_password      => $db_pass,
        dns_webserver_address => '::',
        dns_api_key           => $pdns_api_key,
        dns_api_allow_from    => $pdns_api_allow_from,
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

    firewall::service { 'pdns-rest-api':
        proto  => 'tcp',
        port   => [8081],
        srange => [$pdns_auth_hosts + $designate_hosts].flatten,
        drange => $dns_webserver_allow_to,
    }
}
