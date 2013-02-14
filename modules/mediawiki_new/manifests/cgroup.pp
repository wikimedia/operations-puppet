class mediawiki_new::cgroup {
	require mediawiki_new::cgroup::setup

	service { "mw-cgroup":
		provider => upstart,
		ensure => running;
	}
}
class mediawiki_new::cgroup::setup {
	package { [ 'cgroup-bin' ]:
		ensure => latest;
	}
	file {
		"/etc/init/mw-cgroup.conf":
			owner => root,
			group => root,
			mode => 0644,
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
