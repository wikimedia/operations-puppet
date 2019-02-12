# This role is meant to be applied temporarily
# to stat1005 to test/configure its GPU.
#
class role::statistics::gpu {
    system::role { 'statistics::gpu':
        description => 'Statistics node for GPU testing'
    }
    include ::standard
    include ::profile::base::firewall

    require_package('firmware-amd-graphics')
}
