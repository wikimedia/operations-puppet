# == Class profile::base::linux510
#
# Setup Kernel 5.10 on Buster hosts. Used for special use cases:
# if you want to use it in prod, please sync up with Infrastructure Foundation's
# SREs first for visibility."
# Some use cases:
# - Hosts with GPU (AMD ROCm drivers are published to the kernel, the more recent the better).
#   This includes Machine Learning and Analytics.
# - cloudgw specific NAT settings used by the Cloud team.
# - bnx2x NICs firmware issues (cloudnet servers, see T271058)
#
class profile::base::linux510(
    Boolean $enable = lookup('profile::base::linux510::enable', { 'default_value' => false }),
) {
    # only for Buster
    if $enable and debian::codename::eq('buster') {
        apt::pin { 'linux-image-apt-pin':
            pin      => 'release a=buster-backports',
            package  => 'linux-image-amd64',
            priority => 1001,
        }
    }
}
