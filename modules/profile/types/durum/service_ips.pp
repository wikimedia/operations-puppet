# == Type: Profile::Durum::Service_ips
#
# IP addresses used by the durum hosts.
#
#  [*landing*]
#    [IP address] to listen on for the landing page.
#
#  [*success*]
#    [IP address] to listen on for when user is using Wikidough.
#
#  [*failure*]
#    [IP address] to listen on for when user is not using Wikidough.

type Profile::Durum::Service_ips = Struct[{
    landing => Stdlib::IP::Address,
    success => Stdlib::IP::Address,
    failure => Stdlib::IP::Address,
}]
