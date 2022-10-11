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
class profile::base::linux510 {
    if debian::codename::eq('buster') {
        ensure_packages('linux-image-5.10-amd64')
    }
}
