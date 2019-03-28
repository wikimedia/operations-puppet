# Class systemtap::runtime
# SystemTap runtime environment
#
# Actions:
#   Installs the systemtap-runtime package, necessary to run compiled SystemTap
#   probes.
#
# Usage:
#   include systemtap::runtime
class systemtap::runtime {
    package { 'systemtap-runtime':
        ensure => 'present',
    }
}
