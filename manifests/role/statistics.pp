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
		misc::statistics::dataset_mount,
		misc::statistics::mediawiki,
		misc::statistics::plotting,
		misc::statistics::db::mysql,
		# Aaron Halfaker (halfak) wants MongoDB for his project.
		misc::statistics::db::mongo,
		generic::pythonpip,
		misc::udp2log::udp_filter,
		# generate gerrit stats from stat1.
		misc::statistics::gerrit_stats,
		# rsync logs from logging hosts over to stat1
		misc::statistics::rsync::jobs,
		# event logging packages are useful.
		misc::statistics::eventlogging
}

class role::statistics::www inherits role::statistics {
	system_role { "role::statistics": description => "statistics web server" }

	include
		# stats.wikimedia.org
		misc::statistics::sites::stats,
		# community-analytics.wikimedia.org
		misc::statistics::sites::community_analytics,
		# metrics-api.wikimedia.org
		misc::statistics::sites::metrics_api
}

class role::statistics::eventlogging inherits role::statistics {
    system_role { "role::statistics": description => "event logging aggregator" }

	include misc::statistics::db::mysql,
		misc::statistics::eventlogging
}
