# SPDX-License-Identifier: Apache-2.0

class role::ml_lab::gpu {
    include profile::base::production
    include profile::firewall

    include profile::amd_gpu
    include profile::ceph::client
    include profile::ml_lab
}
