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
    $pdns_host = lookup('profile::openstack::base::pdns::host'),
    $pdns_recursor = lookup('profile::openstack::base::pdns::recursor'),
    $tld = lookup('profile::openstack::base::pdns::tld'),
    $legacy_tld = lookup('profile::openstack::base::pdns::legacy_tld'),
    $private_reverse_zones = lookup('profile::openstack::base::pdns::private_reverse_zones'),
    $aliaser_extra_records = lookup('profile::openstack::base::pdns::recursor_aliaser_extra_records'),
    Array[Stdlib::IP::Address] $extra_allow_from = lookup('profile::openstack::base::pdns::extra_allow_from', {default_value => []}),
    Array[Stdlib::IP::Address] $monitoring_hosts = lookup('monitoring_hosts', {default_value => []}),
    Array[Stdlib::Fqdn]        $controllers      = lookup('profile::openstack::base::openstack_controllers',  {default_value => []}),
    Array[Stdlib::IP::Address] $pdns_api_allow_from = lookup('profile::openstack::base::pdns::pdns_api_allow_from', {'default_value' => []}),
) {

    include ::network::constants
    $allow_from = flatten([
        $::network::constants::labs_networks,
        $extra_allow_from,
        $monitoring_hosts,
        $controllers.map |$host| { ipresolve($host, 4) },
        $controllers.map |$host| { ipresolve($host, 6)}
    ])

    $pdns_host_ip = ipresolve($pdns_host, 4)
    $pdns_recursor_ip_v4 = ipresolve($pdns_recursor, 4)
    $pdns_recursor_ip_v6 = ipresolve($pdns_recursor, 6)

    interface::alias { $title:
        ipv4 => $pdns_recursor_ip_v4,
        ipv6 => $pdns_recursor_ip_v6,
    }

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

    $reverse_zone_rules = inline_template("<% @private_reverse_zones.each do |zone| %><%= zone %>=${pdns_host_ip}, <% end %>")

    class { '::dnsrecursor':
        listen_addresses         => [ $pdns_recursor_ip_v4, $pdns_recursor_ip_v6 ],
        allow_from               => $allow_from,
        additional_forward_zones => "${tld}=${pdns_host_ip}, ${legacy_tld}=${pdns_host_ip}, ${reverse_zone_rules}",
        auth_zones               => 'labsdb=/var/zones/labsdb',
        lua_hooks                => $lua_hooks,
        max_negative_ttl         => 900,
        max_tcp_per_client       => 10,
        max_cache_entries        => 3000000,
        client_tcp_timeout       => 1,
        dnssec                   => 'off',  # T226088 - off until 4.1.x
        require                  => Interface::Alias[$title],
        enable_webserver         => debian::codename::ge('bullseye'),
        api_allow_from           => $pdns_api_allow_from,
    }

    class { '::dnsrecursor::labsaliaser':
        username              => $observer_user,
        password              => $observer_password,
        nova_api_url          => "https://${keystone_api_fqdn}:25000/v3",
        extra_records         => $aliaser_extra_records,
        observer_project_name => $observer_project,
    }

    $ferm_srange = "(${allow_from.join(' ')})"

    ferm::service { 'recursor_udp_dns_rec':
        proto  => 'udp',
        port   => '53',
        srange => $ferm_srange,
    }

    ferm::service { 'recursor_tcp_dns_rec':
        proto  => 'tcp',
        port   => '53',
        srange => $ferm_srange,
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

    dnsrecursor::monitor { [ $pdns_recursor_ip_v4, $pdns_recursor_ip_v6 ]: }
}
