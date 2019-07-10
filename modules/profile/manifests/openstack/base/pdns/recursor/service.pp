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
    $nova_controller = hiera('profile::openstack::base::nova_controller'),
    $keystone_host = hiera('profile::openstack::base::keystone_host'),
    $observer_user = hiera('profile::openstack::base::observer_user'),
    $observer_password = hiera('profile::openstack::base::observer_password'),
    $observer_project = hiera('profile::openstack::base::observer_project'),
    $pdns_host = hiera('profile::openstack::base::pdns::host'),
    $pdns_recursor = hiera('profile::openstack::base::pdns::recursor'),
    $tld = hiera('profile::openstack::base::pdns::tld'),
    $private_reverse_zones = hiera('profile::openstack::base::pdns::private_reverse_zones'),
    $aliaser_extra_records = hiera('profile::openstack::base::pdns::recursor_aliaser_extra_records'),
    ) {

    include ::network::constants
    $all_networks = flatten([$::network::constants::production_networks, $::network::constants::labs_networks])

    $pdns_host_ip = ipresolve($pdns_host,4)
    $pdns_recursor_ip = ipresolve($pdns_recursor,4)

    interface::alias { $title:
        ipv4 => $pdns_recursor_ip,
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
            listen_addresses         => [$pdns_recursor_ip],
            allow_from               => $all_networks,
            additional_forward_zones => "${tld}=${pdns_host_ip}, ${reverse_zone_rules}",
            auth_zones               => 'labsdb=/var/zones/labsdb',
            lua_hooks                => $lua_hooks,
            max_negative_ttl         => 900,
            max_tcp_per_client       => 10,
            max_cache_entries        => 3000000,
            client_tcp_timeout       => 1,
            dnssec                   => 'off',  # T226088 - off until 4.1.x
            require                  => Interface::Alias[$title]
    }

    class { '::dnsrecursor::labsaliaser':
        username              => $observer_user,
        password              => $observer_password,
        nova_api_url          => "http://${keystone_host}:5000/v3",
        extra_records         => $aliaser_extra_records,
        observer_project_name => $observer_project,
    }

    ferm::service { 'recursor_udp_dns_rec':
        proto  => 'udp',
        port   => '53',
        srange => '$LABS_NETWORKS',
    }

    ferm::service { 'recursor_tcp_dns_rec':
        proto  => 'tcp',
        port   => '53',
        srange => '$LABS_NETWORKS',
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
