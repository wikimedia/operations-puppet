# SPDX-License-Identifier: Apache-2.0

# K8s::ClusterCIDR defines the CIDR(s) used by pods.
#
# As all clusters do have reservations for IPv4 and IPv6 CIDRs.
# This enforces both ranges to be present in hiera but the IPv6
# CIDR might not always be used currently.
#
type K8s::ClusterCIDR = Struct[{
    v4 => Stdlib::IP::Address::V4::CIDR,
    v6 => Stdlib::IP::Address::V6::CIDR,
}]
