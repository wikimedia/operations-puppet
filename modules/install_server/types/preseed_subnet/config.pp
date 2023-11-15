# SPDX-License-Identifier: Apache-2.0
type Install_server::Preseed_subnet::Config = Struct[{
    subnet_gateway  => Stdlib::IP::Address,
    subnet_mask     => Stdlib::IP::Address,
    datacenter_name => Wmflib::Sites,
    public_subnet   => Boolean,
}]
