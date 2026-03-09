# SPDX-License-Identifier: Apache-2.0
class profile::wmcs::kubeadm::preflight_checks () {
    # kubeadm preflight checks:
    # Ncpu should be >= 2
    if $facts['processorcount'] < 2 {
        fail('Please apply this profile into a VM with nCPU >= 2')
    }
}
