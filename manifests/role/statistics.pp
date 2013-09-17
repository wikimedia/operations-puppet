# statistics servers (per ezachte - RT 2162)

class role::statistics {
	include standard,
		admins::roots,
		misc::statistics::user,
		backup::client,  # amanda backups
		misc::statistics::base,
		base::packages::emacs
}

class role::statistics::cruncher inherits role::statistics {
	system_role { "role::statistics": description => "statistics number crunching server" }

	# include classes needed for crunching data on stat1.
	include misc::geoip,
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
		misc::statistics::rsync::jobs::eventlogging,
		# geowiki: bringing data from production slave db to research db
		misc::statistics::geowiki::jobs::data,
		# geowiki: generate limn files from research db and push them
		misc::statistics::geowiki::jobs::limn,
		# geowiki: monitors the geowiki files of http://gp.wmflabs.org/
		misc::statistics::geowiki::jobs::monitoring
}

class role::statistics::www inherits role::statistics {
	system_role { "role::statistics": description => "statistics web server" }

	include
		misc::statistics::webserver,
		# stats.wikimedia.org
		misc::statistics::sites::stats,
		# community-analytics.wikimedia.org
		misc::statistics::sites::community_analytics,
		# metrics.wikimedia.org
		misc::statistics::sites::metrics,
		# reportcard.wikimedia.org
		misc::statistics::sites::reportcard,
		# rsync public datasets from stat1 hourly
		misc::statistics::public_datasets
}

class role::statistics::private inherits role::statistics {
	system_role { "role::statistics": description => "statistics private data host" }

	# include classes needed for crunching private data on stat1002
	include misc::geoip,
		misc::statistics::dataset_mount,
		misc::statistics::mediawiki,
		misc::statistics::plotting,
		generic::pythonpip,
		misc::udp2log::udp_filter,
		# rsync logs from logging hosts
		# wikistats code is run here to
		# generate stats.wikimedia.org data
		misc::statistics::wikistats,
		misc::statistics::packages::java,
		misc::statistics::rsync::jobs::webrequest,
		misc::statistics::rsync::jobs::eventlogging
}
