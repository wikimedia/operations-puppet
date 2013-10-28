# misc::download

class misc::download::cron-rsync-dumps {
        file {	'/usr/local/bin/rsync-dumps.sh':
		mode   => 0755,
		owner  => root,
		group  => root,
		path   => '/usr/local/bin/rsync-dumps.sh',
		source => 'puppet:///files/misc/scripts/rsync-dumps.sh';
	}

	cron { 'rsync-dumps':
		ensure  => present,
		command => '/usr/local/bin/rsync-dumps.sh',
		user    => root,
		minute  => '0',
		hour    => '*/2',
		require => File['/usr/local/bin/rsync-dumps.sh'];
	}
}

class misc::download-wikimedia {
	system::role { "misc::download-wikimedia": description => "download.wikimedia.org" }

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
		ensure => present;
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

	include generic::higher_min_free_kbytes

	monitor_service { "lighttpd http": description => "Lighttpd HTTP", check_command => "check_http" }
	monitor_service { "nfs": description => "NFS", check_command => "check_tcp!2049" }
}

class misc::download-primary {
	system::role { "misc::download-primary": description => "Service for rsync to internal download mirrors" }

        include role::mirror::common

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
	system::role { "misc::download-mirror": description => "Service for rsync to external download mirrors" }

        include role::mirror::common

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

	system::role { "misc::download-mediawiki": description => "MediaWiki download" }

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

class misc::download-gluster {
	include role::mirror::common
	include generic::gluster-client

	system::role { "misc::download-gluster": description => "Gluster dumps copy" }

	file {
                '/mnt/glusterpublicdata':
			ensure => directory,
			owner => "root",
			group => "root",
			mode => 0775;
	}

	mount {
		'/mnt/glusterpublicdata':
			ensure  => present,
			device  => 'labstore1.pmtpa.wmnet:/publicdata-project',
			fstype  => 'glusterfs',
			options => 'defaults,_netdev=bond0,log-level=WARNING,log-file=/var/log/gluster.log',
			require => [Package['glusterfs-client'], File['/mnt/glusterpublicdata']];
	}

	file {
		'/usr/local/bin/wmfdumpsmirror.py':
			ensure => present,
			mode   => '0755',
			source => 'puppet:///files/mirror/wmfdumpsmirror.py';
		'/usr/local/sbin/gluster-rsync-cron.sh':
			ensure => present,
			mode   => '0755',
			source => 'puppet:///files/mirror/gluster-rsync-cron.sh',
	}

	cron {
	       'dumps_gluster_rsync':
			ensure      => present,
			user        => root,
			minute      => '50',
			hour        => '3',
			command     => '/usr/local/sbin/gluster-rsync-cron.sh',
			environment => 'MAILTO=ops-dumps@wikimedia.org',
			require     => [ File[ ['/usr/local/bin/wmfdumpsmirror.py', '/usr/local/sbin/gluster-rsync-cron.sh'],
					       ['/mnt/glusterpublicdata'] ] ];
	}
}


class misc::kiwix-mirror {
	# TODO: add system::role

	group { mirror:
		ensure => "present";
	}

	user { mirror:
		name => "mirror",
		gid => "mirror",
		groups => [ "www-data"],
		membership => "minimum",
		home => "/data/home",
		shell => "/bin/bash";
	}

	file {
		"/data/xmldatadumps/public/kiwix":
			ensure => "/data/xmldatadumps/public/other/kiwix";
		"/data/xmldatadumps/public/other/kiwix":
			owner => "mirror",
			group => "mirror",
			mode => 0644,
			ensure => present;
	}

	cron { kiwix-mirror-update:
		command => "rsync -vzrlptD  download.kiwix.org::download.kiwix.org/zim/0.9/ /data/xmldatadumps/public/other/kiwix/zim/0.9/ >/dev/null 2>&1",
		user => mirror,
		minute => '*/15',
		ensure => present;
	}

}

