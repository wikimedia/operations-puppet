# SPDX-License-Identifier: Apache-2.0
type Netbox::Prefix = Struct[{
    public             => Boolean,
    description        => String,
    status             => Netbox::Prefix::Status,
    Optional['site']   => Wmflib::Sites,
    Optional['role']   => String,
    Optional['vlan']   => String,
    Optional['tenant'] => String,
}]
