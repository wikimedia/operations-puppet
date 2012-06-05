class role::ipv6relay {

	include generic::sysctl::advanced-routing-ipv6

	interface_tun6to4 { "tun6to4": }

}
