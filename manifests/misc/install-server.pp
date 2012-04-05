# misc/install-server.pp

class misc::install-server {
	system_role { "misc::install-server": description => "Install server" }

	class web-server {
		package { "lighttpd":
			ensure => latest;
		}

		file { "lighttpd.conf":
			mode => 0444,
			owner => root,
			group => root,
			path => "/etc/lighttpd/lighttpd.conf",
			source => "puppet:///files/lighttpd/install-server.conf";
		}

		service { "lighttpd":
			require => [ File["lighttpd.conf"], Package[lighttpd] ],
			subscribe => File["lighttpd.conf"],
			ensure => running;
		}

		# Monitoring
		monitor_service { "http": description => "HTTP", check_command => "check_http" }
	}

	class tftp-server {
		system_role { "misc::tftp-server": description => "TFTP server" }

		# TODO: replace this by iptables.pp definitions
		$iptables_command = "
			/sbin/iptables -F tftp;
			/sbin/iptables -A tftp -s 10.0.0.0/8 -j ACCEPT;
			/sbin/iptables -A tftp -s 208.80.152.0/22 -j ACCEPT;
			/sbin/iptables -A tftp -s 91.198.174.0/24 -j ACCEPT;
			/sbin/iptables -A tftp -j DROP;
			/sbin/iptables -I INPUT -p udp --dport tftp -j tftp
			"

		exec { tftp-firewall-rules:
			command => $iptables_command,
			onlyif => "/sbin/iptables -N tftp",
			path => "/sbin",
			timeout => 5,
			user => root
		}

		file {
			 ["/srv/tftpboot", "/srv/tftpboot/restricted/" ]:
				mode => 0755,
				owner => root,
				group => root,
				ensure => directory;
			"/tftpboot":
				ensure => "/srv/tftpboot";
		}

		package { openbsd-inetd:
			ensure => latest;
		}

		# Started by inetd
		package { "atftpd":
			require => [ Package[openbsd-inetd], Exec[tftp-firewall-rules] ],
			ensure => latest;
		}
	}

	class caching-proxy {
		system_role { "misc::caching-proxy": description => "Caching proxy server" }

		file { "/etc/squid/squid.conf":
			require => Package[squid],
			mode => 0444,
			owner => root,
			group => root,
			path => "/etc/squid/squid.conf",
			source => "puppet:///files/squid/apt-proxy.conf",
			ensure => present;
		}

		package { squid:
			ensure => latest;
		}

		service { squid:
			require => [ File["/etc/squid/squid.conf"], Package[squid] ],
			subscribe => File["/etc/squid/squid.conf"],
			ensure => running;
		}

		# Monitoring
		monitor_service { "squid": description => "Squid", check_command => "check_tcp!8080" }
	}

	class ubuntu-mirror {
		system_role { "misc::ubuntu-mirror": description => "Public Ubuntu mirror" }

		# Top level directory must exist
		file { "/srv/ubuntu/":
			require => Systemuser[mirror],
			mode => 0755,
			owner => mirror,
			group => mirror,
			path => "/srv/ubuntu/",
			ensure => directory;
		}

		# Update script
		file { "update-ubuntu-mirror":
			mode => 0555,
			owner => root,
			group => root,
			path => "/usr/local/sbin/update-ubuntu-mirror",
			source => "puppet:///files/misc/update-ubuntu-mirror";
		}

		# System user and group for mirroring
		systemuser { mirror: name => "mirror", home => "/var/lib/mirror" }

		# Mirror update cron entry
		cron { update-ubuntu-mirror:
			require => [ Systemuser[mirror], File["update-ubuntu-mirror"] ],
			command => "/usr/local/sbin/update-ubuntu-mirror > /dev/null",
			user => mirror,
			hour => '*/6',
			minute => 43,
			ensure => present;
		}
	}

	class apt-repository {
		system_role { "misc::apt-repository": description => "APT repository" }

		package { [ "dpkg-dev", "gnupg", "reprepro" ]:
			ensure => latest;
		}

		# TODO: add something that sets up /etc/environment for reprepro

		file {
			"/srv/wikimedia/":
				mode => 0755,
				owner => root,
				group => root,
				path => "/srv/wikimedia/",
				ensure => directory;
			"/usr/local/sbin/update-repository":
				mode => 0555,
				owner => root,
				group => root,
				path => "/usr/local/sbin/update-repository",
				content => "#! /bin/bash
echo 'update-repository is no longer used; the Wikimedia APT repository is now managed using 'reprepro'. See [[wikitech:reprepro]] for more information.'
"
		}

		alert("The Wikimedia Archive Signing GPG keys need to be installed manually on this host.")
	}

	class preseed-server {
		file { "/srv/autoinstall":
			mode => 0444,
			owner => root,
			group => root,
			path => "/srv/autoinstall/",
			source => "puppet:///files/autoinstall",
			recurse => true,
			links => manage
		}
	}

	class dhcp-server {
		file { "/etc/dhcp3/" :
			require => Package[dhcp3-server],
			ensure => directory,
			recurse => true,
			owner => "root",
			group => "root",
			mode => 0444,
			source => "puppet:///files/dhcpd";
		}

		package { dhcp3-server:
			ensure => latest;
		}

		service { dhcp3-server:
			require => [ Package[dhcp3-server],
			File["/etc/dhcp3" ] ],
			subscribe => File["/etc/dhcp3" ],
			ensure => running;
		}
	}

	include misc::install-server::ubuntu-mirror,
		misc::install-server::apt-repository,
		misc::install-server::preseed-server,
		misc::install-server::tftp-server,
		misc::install-server::caching-proxy,
		misc::install-server::web-server,
		misc::install-server::dhcp-server
}
