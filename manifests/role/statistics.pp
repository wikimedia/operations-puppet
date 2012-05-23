# statistics servers (per ezachte - RT 2162)

class role::statistics {
	system_role { "role::statistics": description => "statistics server" }

	include standard,
		admins::roots,
		geoip,
		geoip::packages::python,
		generic::packages::git-core,
		misc::statistics::base,
		misc::statistics::mediawiki,
		misc::statistics::plotting,
		misc::statistics::db,
		generic::pythonpip,
		udp2log::udp_filter

}
