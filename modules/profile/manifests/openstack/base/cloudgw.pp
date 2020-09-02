class profile::openstack::base::cloudgw (
) {
    class { '::nftables':
        ensure_service => 'present',
    }

    class { '::profile::nftables::basefirewall': }
    contain '::profile::nftables::basefirewall'

    # placeholder for HA stuff: keepalived and conntrackd
}
