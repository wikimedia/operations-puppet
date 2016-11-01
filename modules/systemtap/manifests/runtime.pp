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

    apt::pin { 'systemtap-runtime':
        pin      => 'release a=jessie-backports',
        priority => '1001',
        before   => Package['systemtap-runtime'],
    }
}
