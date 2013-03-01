class mediawiki::cgroup {
	package { 'cgroup-bin':
		ensure => present,
	}

	file { '/etc/init/mw-cgroup.conf':
		owner   => root,
		group   => root,
		mode    => '0644',
		source  => 'puppet:///modules/mediawiki/cgroup/mw-cgroup.conf',
		require => Package['cgroup-bin'],
	}

	service { 'mw-cgroup':
		ensure   => running,
		provider => upstart,
		require  => File['/etc/init/mw-cgroup.conf'],
	}

	file { '/usr/local/bin/cgroup-mediawiki-clean':
		owner  => root,
		group  => root,
		mode   => '0755',
		source => 'puppet:///modules/mediawiki/cgroup/cgroup-mediawiki-clean',
	}
}
