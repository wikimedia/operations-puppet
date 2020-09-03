class profile::openstack::base::cloudgw (
) {
    # need nft >= 0.9.6 and kernel >= 5.6 to use some of the concatenated rules
    apt::pin { 'nft-from-buster-bpo':
        package  => 'nftables libnftables1 libnftnl11 linux-image-amd64',
        pin      => 'release n=buster-backports',
        priority => 1001,
        before   => Class['::nftables'],
        notify   => Exec['apt-get-update'],
    }

    exec { 'apt-get-update':
        command     => '/usr/bin/apt-get update',
        refreshonly => true,
    }

    class { '::nftables':
        ensure_service => 'present',
    }

    # placeholder for HA stuff: keepalived and conntrackd
}
