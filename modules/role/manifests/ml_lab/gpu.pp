# SPDX-License-Identifier: Apache-2.0

class role::ml_lab::gpu {
    system::role { 'ml_lab::gpu':
        description => 'ML experimenting and development machines with AMD GPUs'
    }

    include profile::base::production
    include profile::firewall

    include profile::amd_gpu
}
