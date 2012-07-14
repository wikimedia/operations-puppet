class misc::parsoid {
	package { [ "nodejs", "npm" ]:
		ensure => latest
	}

	file {
		"/var/lib/parsoid":
			ensure => directory,
			owner => parsoid,
			group => parsoid,
			mode => 0755;
		"/etc/init.d/parsoid":
			source => "puppet:///files/misc/parsoid.init",
			owner => root,
			group => root,
			mode => 0555;
		"/usr/bin/parsoid":
			source => "puppet:///files/misc/parsoid",
			owner => root,
			group => root,
			mode => 0555;
	}

	systemuser {
		parsoid:
			name => "parsoid",
			default_group => "parsoid",
			home => "/var/lib/parsoid";
	}

	git::clone {
		"parsoid":
			directory => "/var/lib/parsoid/Parsoid",
			owner => parsoid,
			group => parsoid,
			origin => "https://gerrit.wikimedia.org/r/p/mediawiki/extensions/Parsoid.git",
			#ensure => latest,   # Not enabling this yet cause I'm not sure it's a good idea
			branch => "master",
			require => [File["/var/lib/parsoid"], Systemuser["parsoid"]];
	}

	exec {
		"parsoid-npm-install":
			command => "/usr/bin/npm install",
			cwd => "/var/lib/parsoid/Parsoid/js/lib",
			user => "parsoid",
			# Needed so we don't try to write /root/.npm and fail
			environment => "HOME=/var/lib/parsoid",
			creates => "/var/lib/parsoid/Parsoid/js/lib/node_modules",
			require => [Package['npm'], Git::Clone['parsoid'], Systemuser["parsoid"]];
	}

	service {
		"parsoid":
			hasstatus => true,
			hasrestart => true,
			enable => true,
			ensure => running,
			require => [File["/etc/init.d/parsoid"], Exec["parsoid-npm-install"]];
	}
}
