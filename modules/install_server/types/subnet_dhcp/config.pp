# SPDX-License-Identifier: Apache-2.0
type Install_server::Subnet_dhcp::Config = Struct[{
    network_mask => Stdlib::IP::Address,
    broadcast_address => Stdlib::IP::Address,
    gateway_ip => Stdlib::IP::Address,
    ip => Stdlib::IP::Address,
}]
