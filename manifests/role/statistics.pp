# statistics servers (per ezachte - RT 2162)

class role::statistics {
	include standard,
		admins::roots,
		misc::statistics::user,
		backup::client,  # amanda backups
		generic::packages::git-core,
		misc::statistics::base,
		base::packages::emacs
}


class role::statistics::cruncher inherits role::statistics {
	system_role { "role::statistics": description => "statistics number crunching server" }

	# include classes needed for crunching data on stat1.
	include geoip,
		geoip::packages::python,
		misc::statistics::mediawiki,
		misc::statistics::plotting,
		misc::statistics::db,
		generic::pythonpip,
		misc::udp2log::udp_filter,
		# generate gerrit stats from stat1.
		misc::statistics::gerrit_stats,
		# rsync logs from logging hosts over to stat1
		misc::statistics::rsync::jobs
}

class role::statistics::www inherits role::statistics {
	system_role { "role::statistics": description => "statistics web server" }
}