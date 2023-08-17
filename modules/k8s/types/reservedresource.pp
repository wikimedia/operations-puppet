# SPDX-License-Identifier: Apache-2.0
# K8s::ReservedResource defines a set of resources to reserve on a node via kubelet --system-reserved or --kube-reserved.
# See: modules/k8s/types/admissionplugins.pp
#
type K8s::ReservedResource = Struct[{
    Optional[cpu]               => String,
    Optional[memory]            => String,
    Optional[pid]               => Integer,
    Optional[ephemeral-storage] => String,
}]
