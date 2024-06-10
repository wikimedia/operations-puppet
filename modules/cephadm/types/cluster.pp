# SPDX-License-Identifier: Apache-2.0
# Type for describing a cephadm cluster
type Cephadm::Cluster = Struct[{
    cluster_name => String[1],
    mon_network  => Wmflib::IP::Address::CIDR,
    controller   => Stdlib::Host,
    monitors     => Array[Stdlib::Host, 1],
    osds         => Array[Stdlib::Host, 1],
    rgws         => Optional[Array[Stdlib::Host, 1]],
}]
