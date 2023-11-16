# SPDX-License-Identifier: Apache-2.0
type Install_server::Audience_dhcp::Config = Struct[{
    subnets => Hash[String[1], Install_server::Subnet_dhcp::Config],
    domain => String[1]
}]
