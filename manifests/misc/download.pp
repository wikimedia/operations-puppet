# misc::download

class misc::download-wikimedia {
	system_role { "misc::download-wikimedia": description => "download.wikimedia.org" }

	package { lighttpd:
		ensure => latest;
	}

	file {
		"/etc/lighttpd/lighttpd.conf":
		mode => 0444,
		owner => root,
		group => root,
		path => "/etc/lighttpd/lighttpd.conf",
		source => "puppet:///files/download/lighttpd.conf";
	}

	service { lighttpd:
		ensure => running;
	}

	package { nfs-kernel-server:
		ensure => latest;
	}

	file { "/etc/exports":
		require => Package[nfs-kernel-server],
		mode => 0444,
		owner => root,
		group => root,
		source => "puppet:///files/download/exports",
	}

	service { nfs-kernel-server:
		require => [ Package[nfs-kernel-server], File["/etc/exports"] ],
	}

        include generic::sysctl::high-bandwidth-rsync

	monitor_service { "lighttpd http": description => "Lighttpd HTTP", check_command => "check_http" }
	monitor_service { "nfs": description => "NFS", check_command => "check_tcp!2049" }
}

class misc::download-primary {
	system_role { "misc::download-primary": description => "Service for rsync to internal download mirrors" }

	package { rsync:
		ensure => latest;
	}

	file {
		"/etc/rsyncd.conf":
			require => Package[rsync],
			mode => 0444,
			owner => root,
			group => root,
			source => "puppet:///files/rsync/rsyncd.conf.downloadprimary";
		"/etc/default/rsync":
			require => Package[rsync],
			mode => 0444,
			owner => root,
			group => root,
			source => "puppet:///files/rsync/rsync.default.downloadprimary";
	}

	service { rsync:
		require => [ Package[rsync], File["/etc/rsyncd.conf"], File["/etc/default/rsync"] ],
		ensure => running;
	}
}

class misc::download-mirror {
	system_role { "misc::download-mirror": description => "Service for rsync to external download mirrors" }

	package { rsync:
		ensure => latest;
	}

	file {
		"/etc/rsyncd.conf":
			require => Package[rsync],
			mode => 0444,
			owner => root,
			group => root,
			source => "puppet:///files/rsync/rsyncd.conf.downloadmirror";
		"/etc/default/rsync":
			require => Package[rsync],
			mode => 0444,
			owner => root,
			group => root,
			source => "puppet:///files/rsync/rsync.default.downloadmirror";
	}

	service { rsync:
		require => [ Package[rsync], File["/etc/rsyncd.conf"], File["/etc/default/rsync"] ],
		ensure => running;
	}
}

class misc::download-mediawiki {

	system_role { "misc::download-mediawiki": description => "MediaWiki download" }

	# FIXME: require apache

	file {
		#apache config
		"/etc/apache2/sites-available/download.mediawiki.org":
			mode => 0444,
			owner => root,
			group => root,
			source => "puppet:///files/apache/sites/download.mediawiki.org";
		"/srv/org/mediawiki":
			owner => "root",
			group => "root",
			mode => 0775,
			ensure => directory;
		"/srv/org/mediawiki/download":
			owner => "mwdeploy",
			group => "mwdeploy",
			mode => 0775,
			ensure => directory;
	}

	apache_site { "download.mediawiki.org": name => "download.mediawiki.org" }
}
