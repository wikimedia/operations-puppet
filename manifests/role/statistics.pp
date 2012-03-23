# statistics servers (per ezachte - RT 2162)

class role::statistics {
	system_role { "role::statistics": description => "statistics server" }

	include standard,
		admins::roots,
		generic::geoip,
		generic::packages::git-core,
		mysql::client,
		misc::statistics::base,
		misc::statistics::plotting,
		generic::pythonpip,
		udp2log::udp_filter

}
