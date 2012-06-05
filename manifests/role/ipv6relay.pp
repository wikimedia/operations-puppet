class role::ipv6relay {

	include generic::sysctl::advanced-routing-ipv6,
		misc::miredo

	interface_tun6to4 { "tun6to4": }

}
