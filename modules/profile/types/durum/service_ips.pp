# SPDX-License-Identifier: Apache-2.0
# == Type: Profile::Durum::Service_ips
#
# IP addresses used by the durum hosts (IPv4 and IPv6).
#
#  [*landing*]
#    [tuple] (IPv4, IPv6) to listen on for the landing page.
#
#  [*success_doh*]
#    [tuple] (IPv4, IPv6) to listen on for when user is using Wikidough (DoH).
#
#  [*failure*]
#    [tuple] (IPv4, IPv6) to listen on for when user is not using Wikidough.
#
#  [*success_dot*]
#    [tuple] (IPv4, IPv6) to listen on for when user is using Wikidough (DoT).

type Profile::Durum::Service_ips = Struct[{
    landing     => Tuple[Stdlib::IP::Address::V4::Nosubnet, Stdlib::IP::Address::V6::Nosubnet],
    success_doh => Tuple[Stdlib::IP::Address::V4::Nosubnet, Stdlib::IP::Address::V6::Nosubnet],
    failure     => Tuple[Stdlib::IP::Address::V4::Nosubnet, Stdlib::IP::Address::V6::Nosubnet],
    success_dot => Tuple[Stdlib::IP::Address::V4::Nosubnet, Stdlib::IP::Address::V6::Nosubnet],
}]
