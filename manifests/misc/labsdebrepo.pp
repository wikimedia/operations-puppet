# Puppet configs to create a local deb repo and add it to your sources.list

class misc::labsdebrepo {
	# manage /srv/project/repo: make sure it's a directory and turn it into a deb repo
	file { "/srv/project/repo":
		ensure => directory;
	}
	# run dpkg-scanpackages . /dev/null | gzip -9c > binary/Packages.gz
	# dpkg-scanpackages is in dpkg-dev
	package { "dpkg-dev":
		ensure => present
	}
	exec { "Turn dir into deb repo":
		cwd => "/srv/project/repo",
		command => "/usr/bin/dpkg-scanpackages . /dev/null | gzip -9c > Packages.gz",
		# only run if Packages.gz is *not* the newest file in the directory
		onlyif => "/usr/bin/test $(find . -newer Packages.gz | wc -l) -gt 0",
		require => [Package["dpkg-dev"], File["/srv/project/repo"]];
	}
	# add the dir-turned-repo to sources.list
	file { "/etc/apt/sources.list.d/labsdebrepo":
		source => "puppet:///files/misc/labsdebrepo",
		require => Exec["Turn dir into deb repo"];
	}
}

