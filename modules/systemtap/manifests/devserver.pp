# Class systemtap::devserver
# Development environment for SystemTap probes
#
# Actions:
#   Installs the systemtap package, the debugging symbols for the Linux kernel
#   and the kernel headers matching the currently running kernel.
#
# Usage:
#   include systemtap::devserver
class systemtap::devserver {
    require_package([
        'build-essential',
        "linux-image-${::kernelrelease}-dbg",
        "linux-headers-${::kernelrelease}",
    ])

    # require_package creates a dynamic intermediate class that makes declaring
    # dependencies a bit strange. Let's use package directly here.
    if !defined(Package['systemtap']) {
        package { 'systemtap':
            ensure => 'present',
        }
    }

    if os_version('debian jessie') {
        apt::pin { 'systemtap':
            package  => 'systemtap systemtap-common systemtap-runtime',
            pin      => 'release a=jessie-backports',
            priority => '1001',
            before   => Package['systemtap'],
        }
    }
}
