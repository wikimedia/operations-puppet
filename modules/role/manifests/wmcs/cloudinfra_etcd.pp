# SPDX-License-Identifier: Apache-2.0
# @summary etcd cluster for Cloud VPS infrastructure services (e.g. requestctl)
class role::wmcs::cloudinfra_etcd () {
    include profile::firewall
    # This profile is poorly named if we end up re-using it, but it does
    # exactly what we want to do for the first iteration so we will use it
    # anyway.
    # TODO: If this works out, rename the profile to be more generic.
    include profile::wmcs::kubeadm::etcd
}
