# SPDX-License-Identifier: Apache-2.0
type Install_server::Datacenter_dhcp::Config = Struct[{
    public => Install_server::Audience_dhcp::Config,
    'private' => Install_server::Audience_dhcp::Config,
    tftp_server => Stdlib::IP::Address,
}]
