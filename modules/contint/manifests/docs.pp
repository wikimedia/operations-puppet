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
