# This role is meant to be applied temporarily
# to stat1005 to test/configure its GPU.
#
class role::statistics::gpu {
    system::role { 'statistics::gpu':
        description => 'Statistics node for GPU testing'
    }
    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::statistics::gpu
}
