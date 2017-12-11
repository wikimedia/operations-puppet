# Class: profile::openstack::pdns::recursor::service
#
# Instances can't communicate directly with other instances
#  via floating IP, but they often want to do DNS lookups for the
#  public IP of other instances (e.g. beta.wmflabs.org).
#
# This recursor does three useful things:
#
#  - It maintains a mapping between floating and private IPs
#  for select instances.  Anytime the upstream DNS server returns
#  a public IP in that mapping, we return the corresponding private
#  IP instead.
#
#  - It relays requests for *.wmflabs to the auth server that knows
#  about such things (defined as $labs_forward)
#
#  - It defines a cname for 'puppet' that resolves to the deployment-appropriate
#  puppetmaster
#
#  Other than that it should act like any other WMF recursor.
#

class profile::openstack::base::pdns::recursor::service(
    $nova_controller = hiera('profile::openstack::base::nova_controller'),
    $observer_user = hiera('profile::openstack::base::observer_user'),
    $observer_password = hiera('profile::openstack::base::observer_password'),
    $observer_project = hiera('profile::openstack::base::observer_project'),
    $pdns_host = hiera('profile::openstack::base::pdns::host'),
    $pdns_recursor = hiera('profile::openstack::base::pdns::recursor'),
    $tld = hiera('profile::openstack::base::pdns::tld'),
    $private_reverse = hiera('profile::openstack::base::pdns::private_reverse'),
    $aliaser_extra_records = hiera('profile::openstack::base::pdns::recursor::aliaser_extra_records'),
    $puppetmaster_hostname = hiera('profile::openstack::base::puppetmaster_hostname'),
    ) {

    include ::network::constants
    $all_networks = $::network::constants::all_networks

    $pdns_host_ip = ipresolve($pdns_host,4)
    $pdns_recursor_ip = ipresolve($pdns_recursor,4)

    interface::alias { $title:
        ipv4 => $pdns_recursor_ip,
    }

    #  We need to alias some public IPs to their corresponding private IPs.
    $alias_file = '/etc/powerdns/labs-ip-alias.lua'
    $metal_resolver = '/etc/powerdns/metaldns.lua'
    $lua_hooks = [$alias_file, $metal_resolver]

    file { '/var/zones':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0444'
    }

    file { '/var/zones/labsdb':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/openstack/base/pdns/recursor/labsdb.zone',
        notify  => Service['pdns-recursor'],
        require => File['/var/zones']
    }

    class { '::dnsrecursor':
            listen_addresses         => [$pdns_recursor_ip],
            allow_from               => $all_networks,
            additional_forward_zones => "${tld}=${pdns_host_ip}, ${private_reverse}=${pdns_host_ip}",
            auth_zones               => 'labsdb=/var/zones/labsdb',
            lua_hooks                => $lua_hooks,
            max_negative_ttl         => 900,
            max_tcp_per_client       => 10,
            max_cache_entries        => 3000000,
            client_tcp_timeout       => 1,
    }

    class { '::dnsrecursor::labsaliaser':
        username              => $observer_user,
        password              => $observer_password,
        nova_api_url          => "http://${nova_controller}:35357/v3",
        extra_records         => $aliaser_extra_records,
        puppetmaster_hostname => $puppetmaster_hostname,
        alias_file            => $alias_file,
        observer_project_name => $observer_project,
    }

    class { '::dnsrecursor::metalresolver':
        metal_resolver => $metal_resolver,
        tld            => $tld
    }

    ferm::service { 'recursor_udp_dns_rec':
        proto => 'udp',
        port  => '53',
    }

    ferm::service { 'recursor_tcp_dns_rec':
        proto => 'tcp',
        port  => '53',
    }

    ferm::rule { 'recursor_skip_dns_conntrack-out':
        desc  => 'Skip DNS outgoing connection tracking',
        table => 'raw',
        chain => 'OUTPUT',
        rule  => 'proto udp sport 53 NOTRACK;',
    }

    ferm::rule { 'recursor_skip_dns_conntrack-in':
        desc  => 'Skip DNS incoming connection tracking',
        table => 'raw',
        chain => 'PREROUTING',
        rule  => 'proto udp dport 53 NOTRACK;',
    }

    ::dnsrecursor::monitor { $pdns_recursor_ip: }
}
