# misc/torrus.pp

class misc::torrus {
	system_role { "misc::torrus": description => "Torrus" }

	package {
		"torrus-common":
			ensure => latest;
		"torrus-apache2":
			before => Class[webserver::apache::service],
			ensure => latest
	}

	@webserver::apache::module { ["perl", "rewrite"]: }
	@webserver::apache::site { "torrus.wikimedia.org":
		docroot => "/var/www",
		includes => ["/etc/torrus/torrus-apache2.conf"]
	}

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

	class discovery {
		# Definition: misc::torrus::discovery
		#
		# This definition generates a torrus discovery DDX file, which Torrus
		# will use to compile its XML config files from SNMP
		#
		# Parameters:
		#	- $subtree: the Torrus subtree path used in the XML config file
		#	- $domain: The domain name to use for SNMP host names
		#	- $snmp_community: The SNMP community needed to query
		#	- $hosts: A list of hosts
		define ddxfile($subtree, $domain="", $snmp_community="public", $hosts=[]) {
			file { "/etc/torrus/discovery/${title}":
				require => File["/etc/torrus/discovery"],
				content => template("torrus/generic.ddx.erb"),
				owner => root,
				group => root,
				mode => 0444,
				before => Exec[torrus-discovery],
				notify => Exec[torrus-discovery];
			}
		}
		
		file {
			"/etc/torrus/discovery":
				owner => root,
				group => root,
				mode => 0750,
				ensure => directory;
			"/etc/cron.daily/torrus-discovery":
				source => "puppet:///files/torrus/torrus-discovery",
				owner => root,
				group => root,
				mode => 0550;
		}
		
		exec { "torrus-discovery":
			require => File["/etc/cron.daily/torrus-discovery"],
			path => "/etc/cron.daily/torrus-discovery",
			refreshonly => true,
			notify => Exec[torrus-compile];
		}
	}
	
	include discovery
}
