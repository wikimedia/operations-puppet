class mediawiki_new::cgroup {

	package { [ 'cgroup-bin' ]:
		ensure => latest;
	}
	file {
		"/etc/init/mw-cgroup":
			owner => root,
			group => root,
			mode => 0755,
			source => "puppet:///modules/mediawiki_new/cgroup/mw-cgroup.conf";
	}
	file {
		"/usr/local/bin/cgroup-mediawiki-clean":
			owner => root,
			group => root,
			mode => 0755,
			source => "puppet:///modules/mediawiki_new/cgroup/cgroup-mediawiki-clean";
	}
}
