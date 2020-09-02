class profile::openstack::codfw1dev::cloudgw (
    Array[String]                 $dmz_cidr       = lookup('profile::openstack::codfw1dev::cloudgw::dmz_cidr',         {default_value => ['0.0.0.0/0 . 0.0.0.0/0']}),
    Stdlib::IP::Address           $routing_source = lookup('profile::openstack::codfw1dev::cloudgw::routing_source_ip',{default_value => '185.15.57.1'}),
    Stdlib::IP::Address::V4::CIDR $vir_subnet     = lookup('profile::openstack::codfw1dev::cloudgw::virt_subnet_cidr', {default_value => '172.16.128.0/24'}),
    String                        $nic_host       = lookup('profile::openstack::codfw1dev::cloudgw::nic_host',         {default_value => 'bond0.2118'}),
    String                        $nic_virt       = lookup('profile::openstack::codfw1dev::cloudgw::nic_virt',         {default_value => 'bond0.2120'}),
    String                        $nic_wan        = lookup('profile::openstack::codfw1dev::cloudgw::nic_wan',          {default_value => 'bond0.21xx'}),
) {
    class { '::profile::openstack::base::cloudgw': }
    contain '::profile::openstack::base::cloudgw'

    nftables::file { 'cloudgw':
        ensure  => present,
        order   => 1,
        content => template('profile/openstack/codfw1dev/cloudgw.nft.erb'),
    }
}
