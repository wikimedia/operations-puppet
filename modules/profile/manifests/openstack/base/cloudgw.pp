class profile::openstack::base::cloudgw (
) {
    class { '::nftables':
        ensure_service => 'present',
    }

    # placeholder for HA stuff: keepalived and conntrackd
}
