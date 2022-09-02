# SPDX-License-Identifier: Apache-2.0
# K8s::ClusterCIDR defines the CIRD(s) used by pods.
# Currently, only IPv4 is required as we don't have full dual stack support right now.
#
type K8s::ClusterCIDR = Struct[{
    v4           => Stdlib::IP::Address::V4::CIDR,
    Optional[v6] => Stdlib::IP::Address::V6::CIDR,
}]
