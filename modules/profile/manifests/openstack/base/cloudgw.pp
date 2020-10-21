class profile::openstack::base::cloudgw (
    Array[String]       $all_phy_nics = lookup('profile::openstack::base::cloudgw::all_phy_nics', {default_value => ['eno1']}),
    Stdlib::IP::Address $host_addr    = lookup('profile::openstack::base::cloudgw::host_addr',    {default_value => '127.0.0.2'}),
    Integer             $host_netm    = lookup('profile::openstack::base::cloudgw::host_netm',    {default_value => 8}),
    Stdlib::IP::Address $host_gw      = lookup('profile::openstack::base::cloudgw::host_gw',      {default_value => '127.0.0.1'}),
    String              $host_prefixv6= lookup('profile::openstack::base::cloudgw::host_prefixv6',{default_value => 'fe00:'}),
    Integer             $virt_vlan    = lookup('profile::openstack::base::cloudgw::virt_vlan',    {default_value => 2107}),
    Stdlib::IP::Address $virt_addr    = lookup('profile::openstack::base::cloudgw::virt_addr',    {default_value => '127.0.0.3'}),
    Integer             $virt_netm    = lookup('profile::openstack::base::cloudgw::virt_netm',    {default_value => 8}),
    Stdlib::IP::Address $virt_peer    = lookup('profile::openstack::base::cloudgw::virt_peer',    {default_value => '127.0.0.5'}),
    Stdlib::IP::Address $virt_floating= lookup('profile::openstack::base::cloudgw::virt_floating',{default_value => '127.0.0.5/24'}),
    Stdlib::IP::Address $virt_cidr    = lookup('profile::openstack::base::cloudgw::virt_cidr',    {default_value => '127.0.0.6/24'}),
    Integer             $wan_vlan     = lookup('profile::openstack::base::cloudgw::wan_vlan',     {default_value => 2120}),
    Stdlib::IP::Address $wan_addr     = lookup('profile::openstack::base::cloudgw::wan_addr',     {default_value => '127.0.0.4'}),
    Integer             $wan_netm     = lookup('profile::openstack::base::cloudgw::wan_netm',     {default_value => 8}),
    Stdlib::IP::Address $wan_gw       = lookup('profile::openstack::base::cloudgw::wan_gw',       {default_value => '127.0.0.4'}),
    String              $nic_sshplane = lookup('profile::openstack::base::cloudgw::nic_controlplane', {default_value => 'eno1'}),
    String              $nic_dataplane= lookup('profile::openstack::base::cloudgw::nic_dataplane',    {default_value => 'eno2'}),
) {
    # need nft >= 0.9.6 and kernel >= 5.6 to use some of the concatenated rules
    apt::pin { 'nft-from-buster-bpo':
        package  => 'nftables libnftables1 libnftnl11 linux-image-amd64',
        pin      => 'release n=buster-backports',
        priority => 1001,
        before   => Class['::nftables'],
        notify   => Exec['cloudgw-apt-get-update'],
    }

    exec { 'cloudgw-apt-get-update':
        command     => '/usr/bin/apt-get update',
        refreshonly => true,
    }

    Exec['cloudgw-apt-get-update'] -> Package <| |>

    # force installation of the latest kernel (pinned above)
    Package { 'linux-image-amd64':
        ensure => 'latest',
    }

    # force installation of the latest nft (pinned above)
    class { '::nftables':
        ensure_package => 'latest',
        ensure_service => 'present',
    }

    # network config, routing, bonding + trunking, etc
    $nic_controlplane = $nic_sshplane
    file { '/etc/network/interfaces':
        ensure  => present,
        content => template('profile/openstack/base/cloudgw/interfaces.erb'),
    }

    file { '/etc/iproute2/rt_tables.d/cloudgw.conf':
        ensure  => present,
        content => '10 cloudgw',
    }

    sysctl::parameters { 'forwarding':
        values => {
            'net.ipv4.ip_forward' => '1',
        }
    }

    # placeholder for HA stuff: keepalived and conntrackd
}
