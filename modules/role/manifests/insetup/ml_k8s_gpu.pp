# SPDX-License-Identifier: Apache-2.0
class role::insetup::ml_k8s_gpu {
    include profile::base::production
    include profile::firewall

    # Support for AMD GPUs
    include profile::amd_gpu
}
