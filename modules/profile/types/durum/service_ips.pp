# == Type: Profile::Durum::Service_ips
#
# IP addresses used by the durum hosts.
#
#  [*landing*]
#    [IP address] to listen on for the landing page.
#
#  [*success_doh*]
#    [IP address] to listen on for when user is using Wikidough (DoH).
#
#  [*failure*]
#    [IP address] to listen on for when user is not using Wikidough.
#
#  [*success_dot*]
#    [IP address] to listen on for when user is using Wikidough (DoT).

type Profile::Durum::Service_ips = Struct[{
    landing     => Stdlib::IP::Address,
    success_doh => Stdlib::IP::Address,
    failure     => Stdlib::IP::Address,
    success_dot => Stdlib::IP::Address,
}]
