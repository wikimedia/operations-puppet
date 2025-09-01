# SPDX-License-Identifier: Apache-2.0
class role::ml_k8s::insetup_gpu {
    include profile::base::production
    include profile::firewall

    # Support for AMD GPUs
    include profile::amd_gpu
}
