# Class: profile::openstack::pdns::recursor::service
#
# Instances can't communicate directly with other instances
#  via floating IP, but they often want to do DNS lookups for the
#  public IP of other instances (e.g. beta.wmflabs.org).
#
# This recursor does two useful things:
#
#  - It maintains a mapping between floating and private IPs
#  for select instances.  Anytime the upstream DNS server returns
#  a public IP in that mapping, we return the corresponding private
#  IP instead.  This includes a deploy-specific resolution for the
#  puppet. domain.
#
#  - It relays requests for *.wmflabs to the auth server that knows
#  about such things (defined as $labs_forward)
#
#  Other than that it should act like any other WMF recursor.
#

class profile::openstack::base::pdns::recursor::service(
    Stdlib::Fqdn $keystone_api_fqdn = lookup('profile::openstack::base::keystone_api_fqdn'),
    $observer_user = lookup('profile::openstack::base::observer_user'),
    $observer_password = lookup('profile::openstack::base::observer_password'),
    $observer_project = lookup('profile::openstack::base::observer_project'),
    $legacy_tld = lookup('profile::openstack::base::pdns::legacy_tld'),
    $private_reverse_zones = lookup('profile::openstack::base::pdns::private_reverse_zones'),
    $aliaser_extra_records = lookup('profile::openstack::base::pdns::recursor_aliaser_extra_records'),
    Array[Stdlib::IP::Address] $extra_allow_from = lookup('profile::openstack::base::pdns::extra_allow_from', {default_value => []}),
    Array[Stdlib::IP::Address] $monitoring_hosts = lookup('monitoring_hosts', {default_value => []}),
    Array[OpenStack::ControlNode] $openstack_control_nodes = lookup('profile::openstack::base::openstack_control_nodes',  {default_value => []}),
    Array[Stdlib::IP::Address] $pdns_api_allow_from = lookup('profile::openstack::base::pdns::pdns_api_allow_from', {'default_value' => []}),
    Optional[Stdlib::IP::Address::V4::Nosubnet] $bgp_vip = lookup('profile::openstack::base::pdns::recursor::bgp_vip', {'default_value' => undef}),
    Array[Hash]                $pdns_hosts       = lookup('profile::openstack::base::pdns::hosts'),
) {
    $this_host_entry = ($pdns_hosts.filter | $host | {$host['host_fqdn'] == $::fqdn})[0]
    $query_local_address = $this_host_entry['auth_fqdn']

    include ::network::constants
    $allow_from = flatten([
        $::network::constants::cloud_networks,
        $extra_allow_from,
        $monitoring_hosts,
        $openstack_control_nodes.map |OpenStack::ControlNode $node| {
            dnsquery::lookup($node['cloud_private_fqdn'], true)
        }.flatten
    ])

    #  We need to alias some public IPs to their corresponding private IPs.
    $aliaser_source = 'puppet:///modules/profile/openstack/base/pdns/recursor/labsaliaser.lua'

    $aliaser_file = '/etc/powerdns/labs-ip-aliaser.lua'
    file { $aliaser_file:
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => $aliaser_source,
    }
    $lua_hooks = [$aliaser_file]

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
        source  => 'puppet:///modules/profile/openstack/base/pdns/recursor/labsdb.zone',
        notify  => Service['pdns-recursor'],
        require => File['/var/zones']
    }

    $pdns_auth_addrs = $pdns_hosts.map |$item| { dnsquery::lookup($item['auth_fqdn'], true) }.flatten.sort.join(';')
    $reverse_zone_rules = inline_template("<% @private_reverse_zones.each do |zone| %><%= zone %>=${pdns_auth_addrs}, <% end %>")

    class { '::dnsrecursor':
        listen_addresses         => [$bgp_vip],
        allow_from               => $allow_from,
        additional_forward_zones => "${legacy_tld}=${pdns_auth_addrs}, ${reverse_zone_rules}",
        auth_zones               => 'labsdb=/var/zones/labsdb',
        lua_hooks                => $lua_hooks,
        max_negative_ttl         => 30,
        max_tcp_per_client       => 10,
        max_cache_entries        => 3000000,
        client_tcp_timeout       => 1,
        dnssec                   => 'off',  # T226088 - off until 4.1.x
        enable_webserver         => debian::codename::ge('bullseye'),
        api_allow_from           => $pdns_api_allow_from,
        query_local_address      => dnsquery::lookup($query_local_address, true),
    }

    class { '::dnsrecursor::labsaliaser':
        username              => $observer_user,
        password              => $observer_password,
        nova_api_url          => "https://${keystone_api_fqdn}:25000/v3",
        extra_records         => $aliaser_extra_records,
        observer_project_name => $observer_project,
    }

    firewall::service { 'recursor_udp_dns_rec':
        proto  => 'udp',
        port   => 53,
        srange => $allow_from,
    }

    firewall::service { 'recursor_tcp_dns_rec':
        proto  => 'tcp',
        port   => 53,
        srange => $allow_from,
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
}
