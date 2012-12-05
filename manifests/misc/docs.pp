class misc::docsite {
	system_role { "misc::docsite": description => "doc site server" }
	file {
		'/etc/apache2/sites-available/doc.wikimedia.org':
			path => '/etc/apache2/sites-available/doc.wikimedia.org',
			mode => 0444,
			owner => root,
			group => root,
			source => 'puppet:///files/apache/sites/doc.wikimedia.org';
		'/srv/org/wikimedia/doc':
			ensure => 'directory';
	}

	apache_site { docs: name => 'doc.wikimedia.org' }
}

class misc::docs::puppet {

	git::clone { "puppetsource":
		directory => "/srv/org/wikimedia/doc/puppetsource",
		branch => "master",
		ensure => latest,
		origin => "https://gerrit.wikimedia.org/r/p/operations/puppet";
	}

	exec { "generate puppet docsite":
		require => git::clone['puppetsource'],
		command => "/usr/bin/puppet doc --mode rdoc --outputdir /srv/org/wikimedia/doc/puppet --modulepath /srv/org/wikimedia/doc/puppetsource/modules --manifestdir /srv/org/wikimedia/doc/puppetsource/manifests",
	}

}
