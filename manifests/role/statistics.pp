# statistics servers (per ezachte - RT 2162)

class role::statistics {
	system_role { "misc::statistics::base": description => "statistics server" }

	include standard,
		admins::roots,
		generic::geoip,
		generic::packages::git-core,
		mysql::client,
		misc::statistics::base,
		misc::statistics::plotting,
		generic::pythonpip

}
