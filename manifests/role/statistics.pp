# statistics servers (per ezachte - RT 2162)

system::role { '::statistics':
    description => 'statistics server',
    }

    # Manually set a list of statistics servers.
    $servers = ['stat1.wikimedia.org', 'stat1001.wikimedia.org',
'stat1002.eqiad.wmnet', 'analytics1027.eqiad.wmnet']

    # set up rsync modules for copying files
    # on statistic servers in /a
    class { 'statistics::rsyncd':
        hosts_allow => $servers }

class role::statistics {
	include standard,
		admins::roots,
		::statistics,
		backup::client,  # amanda backups
		base::packages::emacs
}

class role::statistics::cruncher inherits role::statistics {
	system::role { 'role::statistics':
        description => 'statistics number crunching server',
    }

	# include classes needed for crunching data on stat1.
	include geoip,
		statistics::dataset_mount,
		statistics::mediawiki,
		statistics::packages,
		misc::udp2log::udp_filter,
		# generate gerrit stats from stat1.
		statistics::gerrit_stats,
		statistics::rsync_jobs::eventlogging,
		# geowiki: bringing data from production slave db to research db
		statistics::geowiki::jobs::data,
		# geowiki: generate limn files from research db and push them
		statistics::geowiki::jobs::limn,
		# geowiki: monitors the geowiki files of http://gp.wmflabs.org/
		statistics::geowiki::jobs::monitoring
}

class role::statistics::www inherits role::statistics {
	system::role { 'role::statistics':
        description => 'statistics web server',
    }

	include
		::statistics::apache,
		# stats.wikimedia.org
		statistics::sites::stats,
		# community-analytics.wikimedia.org
		statistics::sites::community_analytics,
		# reportcard.wikimedia.org
		statistics::sites::reportcard,
		# rsync public datasets from stat1 hourly
		statistics::public_datasets
}

class role::statistics::private inherits role::statistics {
	system::role { 'role::statistics':
        description => 'statistics private data host',
    }

	# include classes needed for crunching private data on stat1002
	include geoip,
		statistics::mediawiki,
		statistics::packages,
		misc::udp2log::udp_filter,
		# rsync logs from logging hosts
		# wikistats code is run here to
		# generate stats.wikimedia.org data
		statistics::wikistats,
		statistics::rsync_jobs::webrequest,
		statistics::rsync_jobs::eventlogging
}
