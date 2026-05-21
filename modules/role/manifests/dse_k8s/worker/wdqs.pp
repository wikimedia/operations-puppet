# SPDX-License-Identifier: Apache-2.0
class role::dse_k8s::worker::wdqs {
    # This role is a variant of a standard dse-k8s worker, so include that here
    include role::dse_k8s::worker
    # This profile is where we start to configure these kubernetes workers.
    include profile::kubernetes::node::dse_k8s::wdqs
}
