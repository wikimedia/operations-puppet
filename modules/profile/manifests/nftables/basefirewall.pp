class profile::nftables::basefirewall (
    Array[Stdlib::IP::Address] $cumin_masters           = lookup('cumin_masters',
                                                                {default_value => []}),
    Array[Stdlib::IP::Address] $bastion_hosts           = lookup('bastion_hosts',
                                                                {default_value => []}),
) {
    $bastion_hosts_ipv4 = filter($bastion_hosts) |$addr| { is_ipv4_address($addr) }
    $bastion_hosts_ipv6 = filter($bastion_hosts) |$addr| { is_ipv6_address($addr) }
    $cumin_masters_ipv4 = filter($cumin_masters) |$addr| { is_ipv4_address($addr) }
    $cumin_masters_ipv6 = filter($cumin_masters) |$addr| { is_ipv6_address($addr) }

    nftables::file { 'basefirewall':
        ensure  => 'present',
        content => template('profile/nftables/basefirewall.nft.erb'),
        order   => 0,
    }
}
