# SPDX-License-Identifier: Apache-2.0
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
    stdlib::ensure_packages([
        'build-essential',
        "linux-image-${::kernelrelease}-dbg",
        "linux-headers-${::kernelrelease}",
        'systemtap',
    ])
}
