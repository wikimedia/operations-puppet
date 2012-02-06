# misc/torrus.pp

class misc::torrus {
	system_role { "misc::torrus": description => "Torrus" }

	package { ["torrus-common", "torrus-apache2"]: ensure => latest }

	File { require => Package["torrus-common"] }

	file {
		"/etc/torrus/conf/":
			source => "puppet:///files/torrus/conf/",
			owner => root,
			group => root,
			mode => 0444,
			recurse => remote;
		# TODO: remaining files in xmlconfig, which need to be templates (passwords etc)
		"/etc/torrus/xmlconfig/":
			source => "puppet:///files/torrus/xmlconfig/",
			owner => root,
			group => root,
			mode => 0444,
			recurse => remote;
		"/etc/torrus/templates/":
			source => "puppet:///files/torrus/templates/",
			owner => root,
			group => root,
			mode => 0444,
			recurse => remote;
	}

	exec { "torrus compile":
		command => "/usr/sbin/torrus compile --all",
		require => File[ ["/etc/torrus/conf/", "/etc/torrus/xmlconfig/"] ],
		subscribe => File[ ["/etc/torrus/conf/", "/etc/torrus/xmlconfig/"] ],
		refreshonly => true
	}

	service { "torrus-common":
		require => Exec["torrus compile"],
		subscribe => File[ ["/etc/torrus/conf/", "/etc/torrus/templates/"]],
		ensure => running;
	}

	# TODO: Puppetize the rest of Torrus
}
