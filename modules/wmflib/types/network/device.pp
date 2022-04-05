# SPDX-License-Identifier: Apache-2.0

# @type Wmflib::Network::Device
#
# Describe a network device (e.g. router, switch, etc).
# The parameters below are the same as netops::check define.

type Wmflib::Network::Device = Struct[{
    'role'      => Enum['cr', 'pfw', 'mr', 'msw', 'l2sw', 'l3sw'],
    'site'      => Wmflib::Sites,
    'ipv4'      => Stdlib::IP::Address::V4,
    'ipv6'      => Optional[Stdlib::IP::Address::V6],
    'vrrp_peer' => Optional[Stdlib::Host],
    'alarms'    => Optional[Boolean],
    'bfd'       => Optional[Boolean],
    'vcp'       => Optional[Boolean],
    'bgp'       => Optional[Boolean],
    'parents'   => Optional[Array[Stdlib::Host]],
}]
