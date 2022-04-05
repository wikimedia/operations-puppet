# SPDX-License-Identifier: Apache-2.0

# @type Wmflib::Infra::Device
#
# Describe a network-attached infrastructure device, such as:
# * RIPE Atlas anchors
# * Serial Console Servers

type Wmflib::Infra::Device = Struct[{
    'role'      => Enum['atlas', 'scs'],
    'site'      => Wmflib::Sites,
    'ipv4'      => Stdlib::IP::Address::V4,
    'ipv6'      => Optional[Stdlib::IP::Address::V6],
    'parents'   => Optional[Array[Stdlib::Host]],
}]
