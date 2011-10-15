# misc-servers.pp

# Resource definitions for miscellaneous servers

import "generic-definitions.pp"
import "nagios.pp"

# TODO: perhaps move this to generic-definitions...
class misc::apache2 {

	package { apache2:
		ensure => latest;
	}

}

class misc::bastionhost {
	system_role { "misc::bastionhost": description => "Bastion" }
	
	package { "irssi":
		ensure => absent;
	}
}

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
			 "/srv/tftpboot":
				mode => 0755,
				owner => root,
				group => root,
				ensure => directory;
			 "/srv/tftpboot/restricted/":
				mode => 0755,
				owner => root,
				group => root,
				path => "/srv/tftpboot/restricted/",
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
		package { "subversion":
			ensure => latest;
		}

		file { "/srv/autoinstall":
			mode => 0755,
			owner => root,
			group => root,
			path => "/srv/autoinstall/",
			ensure => directory;
		}
	}

	class dhcp-server {
		file { "/etc/dhcp3/dhcpd.conf":
			require => Package[dhcp3-server],
			mode => 0444,
			owner => root,
			group => root,
			path => "/etc/dhcp3/dhcpd.conf",
			source => "puppet:///files/dhcpd/dhcpd.conf";
		}

		file { [ "/etc/dhcp3/linux-host-entries",
			"/etc/dhcp3/linux-host-entries.ttyS0-57600",
			"/etc/dhcp3/linux-host-entries.ttyS1-57600",
			"/etc/dhcp3/linux-host-entries.ttyS1-115200",
			"/etc/dhcp3/linux-host-entries.ttyS1-9600" ]:

			checksum => md5,
			ensure => file,
			notify => Service[dhcp3-server];
		}

		package { dhcp3-server:
			ensure => latest;
		}

		service { dhcp3-server:
			require => [ Package[dhcp3-server], File["/etc/dhcp3/dhcpd.conf"] ],
			subscribe => File["/etc/dhcp3/dhcpd.conf"],
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

class misc::puppetmaster {
	system_role { "misc::puppetmaster": description => "Puppetmaster" }
	
	package { stompserver:
		ensure => latest;
	}

	# puppetqd does not have an init script.
	service {
		stompserver:
			require => Package[stompserver],
			ensure => stopped;
		puppetqd:
			provider => base,
			start => "/sbin/start-stop-daemon --start --pidfile /var/run/puppet/puppetqd.pid --startas /usr/sbin/puppetqd",
			stop => "/sbin/start-stop-daemon --stop --pidfile /var/run/puppet/puppetqd.pid",
			ensure => stopped;
	}

	cron {
		updategeoipdb:
			environment => "http_proxy=http://brewster.wikimedia.org:8080",
			command => "wget -qO - http://geolite.maxmind.com/download/geoip/database/GeoLiteCountry/GeoIP.dat.gz | gunzip > /etc/puppet/files/misc/GeoIP.dat.new && mv /etc/puppet/files/misc/GeoIP.dat.new /etc/puppet/files/misc/GeoIP.dat; wget -qO - http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz | gunzip > /etc/puppet/files/misc/GeoIPcity.dat.new && mv /etc/puppet/files/misc/GeoIPcity.dat.new /etc/puppet/files/misc/GeoIPcity.dat",
			user => root,
			hour => 3,
			minute => 26,
			ensure => present;
	}
}

class misc::noc-wikimedia {
	system_role { "misc::noc-wikimedia": description => "noc.wikimedia.org" }
	
	package { [ "apache2", "libapache2-mod-php5" ]:
		ensure => latest;
	}

	file {
		"/etc/apache2/sites-available/noc.wikimedia.org":
			require => [ Apache_module[userdir], Apache_module[cgi], Package[libapache2-mod-php5] ],
			path => "/etc/apache2/sites-available/noc.wikimedia.org",
			mode => 0444,
			owner => root,
			group => root,
			source => "puppet:///files/apache/sites/noc.wikimedia.org";
		"/usr/lib/cgi-bin":
			source => "puppet:///files/cgi-bin/noc/",
			recurse => true,
			ignore => ".svn",
			ensure => present;
	}

	apache_module { userdir: name => "userdir" }
	apache_module { cgi: name => "cgi" }

	apache_site { noc: name => "noc.wikimedia.org" }

	service { apache2:
		require => [ Package[apache2], Apache_module[userdir], Apache_module[cgi], Apache_site[noc] ],
		subscribe => [ Package[libapache2-mod-php5], Apache_module[userdir], Apache_module[cgi], Apache_site[noc], File["/etc/apache2/sites-available/noc.wikimedia.org"] ],
		ensure => running;
	}

	# Monitoring
	monitor_service { "http": description => "HTTP", check_command => "check_http" }
}

class misc::blog-wikimedia {
	system_role { "misc::blog-wikimedia": description => "blog.wikimedia.org" }

	require apaches::packages
	
	package { php5-gd:
		ensure => latest;
	}	

	file {
		"/etc/apache2/sites-available/blog.wikimedia.org":
			path => "/etc/apache2/sites-available/blog.wikimedia.org",
			mode => 0444,
			owner => root,
			group => root,
			source => "puppet:///files/apache/sites/blog.wikimedia.org";
	}
}

class misc::download-wikimedia {
	system_role { "misc::download-wikimedia": description => "download.wikimedia.org" }

	package { lighttpd:
		ensure => latest;
	}

	file {
		"/etc/lighttpd/lighttpd.conf":
		mode => 0444,
		owner => root,
		group => root,
		path => "/etc/lighttpd/lighttpd.conf",
		source => "puppet:///files/download/lighttpd.conf";
	}

	service { lighttpd:
		ensure => running;
	}

	package { nfs-kernel-server:
		ensure => latest;
	}

	file { "/etc/exports":
		require => Package[nfs-kernel-server],
		mode => 0444,
		owner => root,
		group => root,
		source => "puppet:///files/download/exports",
	}

	service { nfs-kernel-server:
		require => [ Package[nfs-kernel-server], File["/etc/exports"] ],
	}

	monitor_service { "lighttpd http": description => "Lighttpd HTTP", check_command => "check_http" }
	monitor_service { "nfs": description => "NFS", check_command => "check_tcp!2049" } 

}

class misc::download-mirror {
	system_role { "misc::download-mirror": description => "Service for external download mirrors" }

	package { rsync:
		ensure => latest;
	}

	file {
		"/etc/rsyncd.conf":
			require => Package[rsync],
			mode => 0444,
			owner => root,
			group => root,
			source => "puppet:///files/rsync/rsyncd.conf.downloadmirror";
		"/etc/default/rsync":
			require => Package[rsync],
			mode => 0444,
			owner => root,
			group => root,
			source => "puppet:///files/rsync/rsync.default.downloadmirror";
	}

	service { rsync:
		require => [ Package[rsync], File["/etc/rsyncd.conf"], File["/etc/default/rsync"] ],
		ensure => running;
	}
}

class misc::url-downloader {
	system_role { "misc::url-downloader": description => "Upload-by-URL proxy" }

	file { "/etc/squid/squid.conf":
		require => Package[squid],
		mode => 0444,
		owner => root,
		group => root,
		path => "/etc/squid/squid.conf",
		source => "puppet:///files/squid/copy-by-url-proxy.conf";
	}

	generic::apt::pin-package { squid: }

	package { squid:
		ensure => latest;
	}

	service { squid:
		require => [ File["/etc/squid/squid.conf"], Package[squid], Interface_ip["misc::url-downloader"] ],
		subscribe => File["/etc/squid/squid.conf"],
		ensure => running;
	}
}

class misc::nfs-server::home {
	system_role { "misc::nfs-server::home": description => "/home NFS" }
	
	class backup {
		cron { home-rsync:
			require => File["/root/.ssh/home-rsync"],
			command => '[ -d /home/wikipedia ] && rsync --rsh="ssh -c blowfish-cbc -i /root/.ssh/home-rsync" -azu /home/* db20@tridge.wikimedia.org:~/home/',
			user => root,
			hour => 2,
			minute => 35,
			weekday => 6,
			ensure => present;
		}

		file { "/root/.ssh/home-rsync":
			owner => root,
			group => root,
			mode => 0400,
			source => "puppet:///private/backup/ssh-keys/home-rsync";
		}
	}

	package { nfs-kernel-server:
		ensure => latest;
	}

	file { "/etc/exports":
		require => Package[nfs-kernel-server],
		mode => 0444,
		owner => root,
		group => root,
		source => "puppet:///files/nfs/exports.home";
	}

	service { nfs-kernel-server:
		require => [ Package[nfs-kernel-server], File["/etc/exports"] ],
		subscribe => File["/etc/exports"];
	}

	class monitoring {
		monitor_service { "nfs": description => "NFS", check_command => "check_tcp!2049" }
	}

	include monitoring
}

class misc::nfs-server::home::rsyncd {
	system_role { "misc::nfs-server::home::rsyncd": description => "/home rsync daemon" }

	class { 'generic::rsyncd': config => "home" }
}

class misc::images::rsyncd {
	system_role { "misc::images::rsyncd": description => "images rsync daemon" }

	class { 'generic::rsyncd': config => "export" }
}

class misc::images::rsync {
	system_role { "misc::images::rsync": description => "images rsync mirror host" }

	require misc::images::rsyncd

	$rsync_includes = "
- /upload/centralnotice/
- /upload/ext-dist/
+ /upload/wik*/
+ /private/
- **/thumb/
"
	
	file { "/etc/rsync.includes":
		content => $rsync_includes;
	}

	upstart_job { "rsync-images": install => "true" }
}

# TODO: fold most this in a generic, parameterized 'udp2log' class
class misc::mediawiki-logger {
	system_role { "misc::mediawiki-logger": description => "MediaWiki log server" }

	package { udplog:
		ensure => latest;
	}

	file {
		"/etc/udp2log":
			require => Package[udplog],
			mode => 0444,
			owner => root,
			group => root,
			content => "flush pipe 1 python /usr/local/bin/demux.py\n";
		"/usr/local/bin/demux.py":
			mode => 0544,
			owner => root,
			group => root,
			source => "puppet:///files/misc/demux.py";
		"/etc/logrotate.d/mw-udp2log":
			source => "puppet:///files/logrotate/mw-udp2log",
			mode => 0444;
	}

	service { udp2log:
		require => [ Package[udplog], File[ ["/etc/udp2log", "/usr/local/bin/demux.py"] ] ],
		subscribe => File["/etc/udp2log"],
		ensure => running;
	}
}

class misc::syslog-server {
	system_role { "misc::syslog-server": description => "central syslog server" }
	
	package { syslog-ng:
		ensure => latest;
	}

	file {
		"/etc/syslog-ng/syslog-ng.conf":
			require => Package[syslog-ng],
			source => "puppet:///files/syslog-ng/syslog-ng.conf",
			mode => 0444;
		"/etc/logrotate.d/remote-logs":
			source => "puppet:///files/syslog-ng/remote-logs",
			mode => 0444;
	}

	service { syslog-ng:
		require => [ Package[syslog-ng], File["/etc/syslog-ng/syslog-ng.conf"] ],
		subscribe => File["/etc/syslog-ng/syslog-ng.conf"],
		ensure => running;
	}
}

class misc::extension-distributor {
	system_role { "misc::extension-distributor": description => "MediaWiki extension distributor" }
	
	$extdist_working_dir = "/mnt/upload6/private/ExtensionDistributor"
	$extdist_download_dir = "/mnt/upload6/ext-dist"

	package { xinetd:
		ensure => latest;
	}

	systemuser { extdist: name => "extdist", home => "/var/lib/extdist" }

	file {
		"/etc/xinetd.d/svn_invoker":
			require => [ Package[xinetd], Systemuser[extdist] ],
			owner => root,
			group => root,
			mode => 0444,
			source => "puppet:///files/misc/svn_invoker.xinetd";
		"/etc/logrotate.d/svn-invoker":
			owner => root,
			group => root,
			mode => 0444,
			source => "puppet:///files/logrotate/svn-invoker";
		"$extdist_working_dir":
			owner => extdist,
			group => wikidev,
			mode => 0775;
	}

	cron { extdist_updateall:
		command => "cd $extdist_working_dir/mw-snapshot; for branch in trunk branches/*; do /usr/bin/svn cleanup \$branch/extensions; /usr/bin/svn up \$branch/extensions > /dev/null; done",
		minute => 0,
		user => extdist,
		ensure => present;
	}

	service { xinetd:
		require => [ Package[xinetd], File["/etc/xinetd.d/svn_invoker"] ],
		subscribe => File["/etc/xinetd.d/svn_invoker"],
		ensure => running;
	}
}

class misc::zfs::monitoring {
	monitor_service { "zfs raid": description => "ZFS RAID", check_command => "nrpe_check_zfs" }
}	

class misc::rt::server {
	system_role { "misc::rt::server": description => "RT server" }

	package { [ "request-tracker3.8", "rt3.8-db-mysql", "rt3.8-clients", "libcgi-fast-perl", "lighttpd" ]:
		ensure => latest;
	}

	$rtconf = "# This file is for the command-line client, /usr/bin/rt.\n\nserver http://localhost/rt\n"

	file {
		"/etc/lighttpd/conf-available/10-rt.conf":
			source => "puppet:///files/rt/10-rt.lighttpd.conf";
		"/var/run/fastcgi":
			ensure => directory,
			owner => "www-data",
			group => "www-data",
			mode => 0750;
		"/etc/request-tracker3.8/RT_SiteConfig.d/50-debconf":
			source => "puppet:///files/rt/50-debconf",
			notify => Exec["update-rt-siteconfig"];
		"/etc/request-tracker3.8/RT_SiteConfig.d/80-wikimedia":
			source => "puppet:///files/rt/80-wikimedia",
			notify => Exec["update-rt-siteconfig"];
		"/etc/request-tracker3.8/RT_SiteConfig.pm":
			owner => "root",
			group => "www-data",
			mode => 0440;
		"/etc/request-tracker3.8/rt.conf":
			require => Package["request-tracker3.8"],
			content => $rtconf;
		"/etc/cron.d/mkdir-var-run-fastcgi":
			content => "@reboot	root	mkdir /var/run/fastcgi";
	}

	exec { "update-rt-siteconfig":
		command => "update-rt-siteconfig-3.8",
		path => "/usr/sbin",
		refreshonly => true;
	}

	lighttpd_config { rt: 
		require => [ Package["request-tracker3.8"], File["/etc/lighttpd/conf-available/10-rt.conf"] ],
		name => "10-rt.conf"
	}

	service { lighttpd:
		ensure => running;
	}
}

# TODO: kill.
class misc::wapsite {
	system_role { "misc::wapsite": description => "WAP site server" }

	require generic::webserver::php5

	file {
		"/etc/apache2/sites-available/mobile.wikipedia.org":
			path => "/etc/apache2/sites-available/mobile.wikipedia.org",
			mode => 0444,
			owner => root,
			group => root,
			source => "puppet:///files/apache/sites/mobile.wikipedia.org";
		"/etc/apache2/sites-available/wap.wikipedia.org":
			path => "/etc/apache2/sites-available/wap.wikipedia.org",
			mode => 0444,
			owner => root,
			group => root,
			source => "puppet:///files/apache/sites/wap.wikipedia.org";
		"/srv/mobile.wikipedia.org/":
			mode => 0755,
			owner => root,
			group => root,
			ensure => directory;
	}

	# Install CURL
	generic::apt::pin-package { php5-curl: }
	package { php5-curl: ensure => latest; }

	apache_module { rewrite: name => "rewrite" }

	apache_site {
		mobile:
			name => "mobile.wikipedia.org",
			require => File["/srv/mobile.wikipedia.org/"];
		wap:
			name => "wap.wikipedia.org",
			require => Apache_module[rewrite];
	 }

	# Monitoring
	monitor_service { wapsite:
		check_command => "check_http_url!mobile.wikipedia.org!/about.php",
		description => "Mobile WAP site"
	}
}

class misc::apple-dictionary-bridge {
	system_role { "misc::apple-dictionary-bridge": description => "Apple Dictionary to API OpenSearch bridge" }

	require generic::webserver::php5

	file {
		"/etc/apache2/sites-available/search.wikimedia.org":
			path => "/etc/apache2/sites-available/search.wikimedia.org",
			mode => 0444,
			owner => root,
			group => root,
			source => "puppet:///files/apache/sites/search.wikimedia.org";
		"/srv/search.wikimedia.org/":
			mode => 0755,
			owner => root,
			group => root,
			ensure => directory;
	}

	apache_site { search:
		name => "search.wikimedia.org",
		require => File["/srv/search.wikimedia.org/"];
	}

	# Monitoring
	monitor_service { apple-dictionary-bridge:
		check_command => "check_http_url!search.wikimedia.org!/?site=wikipedia&lang=en&search=wikip&limit=10",
		description => "Apple Dictionary bridge"
	}
}

class misc::irc-server {
	system_role { "misc::irc-server": description => "IRC server" }

$motd = "
*******************************************************
This is the Wikimedia RC->IRC gateway
*******************************************************
Sending messages to channels is not allowed. 

A channel exists for all Wikimedia wikis which have been
changed since the last time the server was restarted. In
general, the name is just the domain name with the .org
left off. For example, the changes on the English Wikipedia
are available at #en.wikipedia

If you want to talk, please join one of the many
Wikimedia-related channels on irc.freenode.net.
"

	file {
		"/usr/local/ircd-ratbox/etc/ircd.conf":
			mode => 0444,
			owner => irc,
			group => irc,
			source => "puppet:///private/misc/ircd.conf";
		"/usr/local/ircd-ratbox/etc/ircd.motd":
			mode => 0444,
			owner => irc,
			group => irc,
			content => $motd;
	}

	# Doesn't work in Puppet 0.25 due to a bug
	service { ircd:
		provider => base,
		binary => "/usr/local/ircd-ratbox/bin/ircd",
		ensure => running;
	}

	# Monitoring
	monitor_service { ircd: description => "ircd", check_command => "check_ircd" }
}

class misc::mediawiki-irc-relay {
	system_role { "misc::mediawiki-irc-relay": description => "MediaWiki RC to IRC relay" }

	package { "python-irclib": ensure => latest; }

	file { "/usr/local/bin/udpmxircecho.py":
		source => "puppet:///private/misc/udpmxircecho.py",
		mode => 0555,
		owner => irc,
		group => irc;
	}

	service { udpmxircecho:
		provider => base,
		binary => "/usr/local/bin/udpmxircecho.py",
		start => "/usr/local/bin/udpmxircecho.py rc-pmtpa ekrem.wikimedia.org",
		ensure => running;
	}
}

class misc::squid-logging::multicast-relay {
	system_role { "misc::squid-logging::multicast-relay": description => "Squid logging unicast to multicast relay" }

	upstart_job { "squid-logging-multicast-relay": install => "true" }

	service { squid-logging-multicast-relay:
		require => Upstart_job[squid-logging-multicast-relay],
		ensure => running;
	}
}

class misc::dc-cam-transcoder {
	system_role { "misc::dc-cam-transcoder": description => "Data center camera transcoder" }

	systemuser { video: name => "video", home => "/var/lib/video" }

	package { "vlc-nox":
		ensure => latest;
	}
}

class misc::etherpad {

	include passwords::etherpad
	$etherpad_admin_pass = $passwords::etherpad::etherpad_admin_pass
	$etherpad_sql_pass = $passwords::etherpad::etherpad_sql_pass

	system_role { "misc::etherpad": description => "Etherpad server" }

	require generic::webserver::modproxy
	
	# NB: this has some GUI going on all up in it. first install must be done by hand.
	package { etherpad:
		ensure => latest;
	}

	service { etherpad:
		require => Package[etherpad],
		ensure => running;
	}

	file { 	
		"/etc/init.d/etherpad":
			source => "puppet:///files/misc/etherpad/etherpad.init",
			mode => 0555,
			owner => root,
			group => root;
		"/etc/apache2/sites-available/etherpad.proxy":
			source => "puppet:///files/misc/etherpad/etherpad.proxy.apache.conf",
			mode => 0444,
			owner => root,
			group => root;
		"/etc/etherpad/etherpad.local.properties":
			content => template("etherpad/etherpad.local.properties.erb"),
			mode => 0444,
			owner => root,
			group => root;
	}

	apache_module { proxy: name => "proxy" }
	apache_site { etherpad_proxy: name => "etherpad.proxy" }

	# Nagios monitoring
	monitor_service { "etherpad http": 
		description => "Etherpad HTTP", 
		check_command => "check_http_on_port!9000";
	}

}

class misc::kiwix-mirror {
	# TODO: add system_role
	
	group { mirror:
		ensure => "present";
	}

	user { mirror:
		name => "mirror",
		gid => "mirror",
		groups => [ "www-data"],
		membership => "minimum", 
		home => "/data/home",
		shell => "/bin/bash";
	}

	file { 
		"/data/xmldatadumps/public/kiwix":
			ensure => "/data/kiwix";
		"/data/kiwix":
			owner => "mirror",
			group => "mirror",
			mode => 0644,
			ensure => present;
	}

	cron { kiwix-mirror-update:
		command => "rsync -vzrlptD  download.kiwix.org::download.kiwix.org/zim/0.9/ /data/kiwix/zim/0.9/ >/dev/null 2>&1",
		user => mirror,
		minute => '*/15',
		ensure => present;
	}

}

# FIXME: merge with misc::contint::test, or remove
class misc::jenkins {

	system_role { "misc::jenkins": description => "jenkins integration server" }

	# FIXME: third party repository
	# This needs to removed, and changed to use Jenkins from our own WMF repository instead.
	exec {
		'jenkins-apt-repo-key':
			unless => '/bin/grep "deb http://pkg.jenkins-ci.org/debian-stable binary/" /etc/apt/sources.list.d/*',
			command => "/usr/bin/wget -q -O - http://pkg.jenkins-ci.org/debian-stable/jenkins-ci.org.key | /usr/bin/apt-key add -";
			
		'jenkins-apt-repo-add':
			subscribe => Exec['jenkins-apt-repo-key'],
			refreshonly => true,
			command => "/bin/echo 'deb http://pkg.jenkins-ci.org/debian-stable binary/' > /etc/apt/sources.list.d/jenkins.list";

		'do-an-apt-get-update':
			subscribe => Exec['jenkins-apt-repo-add'],
			refreshonly => true,
			command => "/usr/bin/apt-get update";
	}

	package { jenkins:
		ensure => latest;
	}

	user { jenkins:
		name => "jenkins",
		groups => [ "wikidev" ]; 
	}
	
	service { 'jenkins':
		enable => true,
		ensure => 'running',
		hasrestart => true,
		start => '/etc/init.d/jenkins start',
		stop => '/etc/init.d/jenkins stop';
	}

	# Nagios monitoring
	monitor_service { "jenkins": description => "jenkins_service_running", check_command => "check_jenkins_service" }

	#file {
		#jenkins stuffs
	#	"/var/lib/jenkins/config.xml":
	#		mode => 0750,
	#		owner => jenkins,
	#		group => nogroup,
	#		require => Package[jenkins],
	#		source => "puppet:///private/misc/jenkins.config.xml";		
	#}
}

# TODO: break this up in different (sub) classes for the different services
class misc::fundraising {

	#include exim::packages
	include passwords::civi

	#what is currently on grosley
	system_role { "misc::fundraising": description => "fundraising sites and operations" }

	package { [ "libapache2-mod-php5", "php-pear", "php5-cli", "php5-common", "php5-curl", "php5-dev", "php5-gd", "php5-mysql", "php5-sqlite", "subversion", "mysql-client-5.1", "phpunit", "dovecot-imapd", "exim4-daemon-heavy", "exim4-config", "python-scipy", "python-matplotlib", "python-dev", "python-setuptools", "python-mysqldb", "libapache2-mod-python" ]:
		ensure => latest;
}

	# civimail user
	group { civimail:
		ensure => "present",
	}

	user { civimail:
		name => "civimail",
		gid => "civimail",
		groups => [ "civimail" ], 
		membership => "minimum",
		password => $passwords::civi::civimail_pass,
		home => "/home/civimail",
		shell => "/bin/sh";
	}

	file {
		#civicrm confs 
		"/srv/org.wikimedia.civicrm/sites/default/civicrm.settings.php":
			mode => 0440,
			owner => www-data,
			group => wikidev,
			source => "puppet:///private/misc/fundraising/civicrm.civicrm.settings.php";
		"/srv/org.wikimedia.civicrm/sites/default/default.settings.php":
			mode => 0440,
			owner => www-data,
			group => wikidev,
			source => "puppet:///private/misc/fundraising/civicrm.default.settings.php";
		"/srv/org.wikimedia.civicrm/sites/default/settings.php":
			mode => 0440,
			owner => www-data,
			group => wikidev,
			source => "puppet:///private/misc/fundraising/civicrm.settings.php";

		#civicrm dev confs
		"/srv/org.wikimedia.civicrm-dev/sites/default/civicrm.settings.php":
			mode => 0440,
			owner => www-data,
			group => wikidev,
			source => "puppet:///private/misc/fundraising/dev.civicrm.civicrm.settings.php";
		"/srv/org.wikimedia.civicrm-dev/sites/default/default.settings.php":
			mode => 0440,
			owner => www-data,
			group => wikidev,
			source => "puppet:///private/misc/fundraising/dev.civicrm.default.settings.php";
		"/srv/org.wikimedia.civicrm-dev/sites/default/settings.php":
			mode => 0440,
			owner => www-data,
			group => wikidev,
			source => "puppet:///private/misc/fundraising/dev.civicrm.settings.php";

		#misc fundraising confs
		"/opt/fundraising-misc/queue_handling/payflowpro/executeStompPFPPendingProcessorSA.php":
			mode => 0444,
			owner => www-data,
			group => wikidev,
			source => "puppet:///private/misc/fundraising/misc.executeStompPFPPendingProcessorSA.php";
		"/opt/fundraising-misc/queue_handling/paypal/IPN/IPNListener_Recurring.php":
			mode => 0444,
			owner => www-data,
			group => wikidev,
			source => "puppet:///private/misc/fundraising/misc.IPNListener_Recurring.php";
		"/opt/fundraising-misc/queue_handling/paypal/IPN/IPNListener_Standalone.php":
			mode => 0444,
			owner => www-data,
			group => wikidev,
			source => "puppet:///private/misc/fundraising/misc.IPNListener_Standalone.php";
		"/srv/org.wikimedia.fundraising/IPNListener_Standalone.php":
			ensure => "/opt/fundraising-misc/queue_handling/paypal/IPN/IPNListener_Standalone.php";	
		"/srv/org.wikimedia.civicrm/fundcore_gateway/paypal":
			ensure => "/opt/fundraising-misc/queue_handling/paypal/IPN/IPNListener_Standalone.php";	
		"/srv/org.wikimedia.civicrm/IPNListener_Recurring.php":
			ensure => "/opt/fundraising-misc/queue_handling/paypal/IPN/IPNListener_Recurring.php";	
		"/srv/org.wikimedia.civicrm/files":
			owner => "www-data",
			group => "wikidev",
			mode => 0775,
			ensure => directory;
		"/srv/org.wikimedia.civicrm-dev/files":
			owner => "www-data",
			group => "wikidev",
			mode => 0775,
			ensure => directory;
		"/srv/org.wikimedia.civicrm/fundcore_gateway":
			owner => "www-data",
			group => "wikidev",
			mode => 0775,
			ensure => directory;
		"/srv/org.wikimedia.civicrm/fundcore_gateway/.htaccess":
			owner => "www-data",
			group => "wikidev",
			mode => 0444,
			content => "<Files paypal>
	ForceType application/x-httpd-php
</Files>";

		#logging stuffs
		"/etc/logrotate.d/paypal_ipn":
			mode => 0444,
			owner => root,
			group => root,
			source => "puppet:///private/misc/fundraising/logrotate.paypal_ipn";
		"/etc/logrotate.d/pfp_pending_processor":
			mode => 0444,
			owner => root,
			group => root,
			source => "puppet:///private/misc/fundraising/logrotate.pfp_pending_processor";
		"/var/log/fundraising/":
			owner => "www-data",
			group => "wikidev",
			mode => 0775,
			ensure => directory;
		"/var/log/fundraising/paypal_ipn/":
			owner => "www-data",
			group => "wikidev",
			mode => 0775,
			ensure => directory;
		"/var/log/fundraising/pfp_pending_processing/":
			owner => "www-data",
			group => "wikidev",
			mode => 0775,
			ensure => directory;

		#apache conf stuffs
		"/etc/apache2/sites-available/000-donate":
			mode => 0444,
			owner => root,
			group => root,
			source => "puppet:///private/misc/fundraising/apache.conf.donate";
		"/etc/apache2/sites-available/002-civicrm":
			mode => 0444,
			owner => root,
			group => root,
			source => "puppet:///private/misc/fundraising/apache.conf.civicrm";
		"/etc/apache2/sites-available/003-civicrm-ssl":
			mode => 0444,
			owner => root,
			group => root,
			source => "puppet:///private/misc/fundraising/apache.conf.civicrm-ssl";
		"/etc/apache2/sites-available/004-civicrm-dev":
			mode => 0444,
			owner => root,
			group => root,
			source => "puppet:///private/misc/fundraising/apache.conf.civicrm-dev";
		"/etc/apache2/sites-available/005-civicrm-dev-ssl":
			mode => 0444,
			owner => root,
			group => root,
			source => "puppet:///private/misc/fundraising/apache.conf.civicrm-dev-ssl";
		"/etc/apache2/sites-available/006-fundraising":
			mode => 0444,
			owner => root,
			group => root,
			source => "puppet:///private/misc/fundraising/apache.conf.fundraising";
		"/etc/apache2/sites-available/007-fundraising-analytics":
			mode => 0444,
			owner => root,
			group => root,
			source => "puppet:///private/misc/fundraising/apache.conf.fundraising-analytics";

		"/usr/local/bin/drush":
			ensure => "/opt/drush/drush";	

		# mail stuff
		"/etc/exim4/exim4.conf":
			content => template("exim/exim4.donate.erb"),
			mode => 0444,
			owner => root,
			group => root;

		"/etc/dovecot/dovecot.conf":
			source => "puppet:///files/dovecot/dovecot.donate.conf",
			mode => 0444,
			owner => root,
			group => root;

		"/var/mail/civimail":
			owner => "civimail",
			group => "civimail",
			mode => 2755,
			ensure => directory;

		# monitoring stuff
		"/etc/nagios/nrpe.d/fundraising.cfg":
			source => "puppet:///files/nagios/nrpe_local.fundraising.cfg",
			mode => 0444,
			owner => root,
			group => root;
		"/etc/sudoers.d/nrpe_fundraising":
			source => "puppet:///files/sudo/sudoers.nrpe_fundraising",
			mode => 0440,
			owner => root,
			group => root;
	}

	#enable apache mods
	apache_module { rewrite: name => "rewrite" }
	apache_module { ssl: name => "ssl" }

	#enable apache sites
	apache_site { donate: name => "000-donate" }
	apache_site { civicrm: name => "002-civicrm" }
	apache_site { civicrm-ssl: name => "003-civicrm-ssl" }
	apache_site { civicrm-dev: name => "004-civicrm-dev" }
	apache_site { civicrm-dev-ssl: name => "005-civicrm-dev-ssl" }
	apache_site { fundraising: name => "006-fundraising" }
	apache_site { fundraising-analytics: name => "007-fundraising-analytics" }

}	

class misc::survey {

# required packages and apache configs for limesurvey install

	system_role { "misc::survey": description => "limesurvey server" }

	package { [ "libapache2-mod-php5", "php-pear", "php5-cli", "php5-common", "php5-gd", "php5-mysql", "mysql-client-5.1" ]:
		ensure => latest;
}

	file {
		# apche configs
		"/etc/apache2/sites-available/survey.wikimedia.org":
			mode => 0444,
			owner => root,
			group => root,
			source => "puppet:///files/apache/sites/survey.wikimedia.org";
	}

	apache_site { survey: name => "survey.wikimedia.org" }

	apache_module { ssl: name => "ssl" }
}

class misc::download-mediawiki {
	
	# TODO: add system_role

	package { [ "wikimedia-task-appserver"]:
		ensure => latest;
}

	file {
		#apache config
		"/etc/apache2/sites-available/download.mediawiki.org":
			mode => 0444,
			owner => root,
			group => root,
			source => "puppet:///files/apache/sites/download.mediawiki.org";
		"/srv/org/mediawiki":
			owner => "root",
			group => "root",
			mode => 0775,
			ensure => directory;
		"/srv/org/mediawiki/download":
			owner => "mwdeploy",
			group => "mwdeploy",
			mode => 0775,
			ensure => directory;
	}

	apache_site { survey: name => "download.mediawiki.org" }

}

class misc::monitoring::htcp-loss {
	system_role { "misc::monitoring::htcp-loss": description => "HTCP packet loss monitor" }

	File {
		require => File["/usr/lib/ganglia/python_modules"],
		notify => Service[gmond]
	}

	# Ganglia
	file {
		"/usr/lib/ganglia/python_modules/htcpseqcheck.py":
			source => "puppet:///files/ganglia/plugins/htcpseqcheck.py";
		"/usr/lib/ganglia/python_modules/htcpseqcheck_ganglia.py":
			source => "puppet:///files/ganglia/plugins/htcpseqcheck_ganglia.py";
		"/usr/lib/ganglia/python_modules/util.py":
			source => "puppet:///files/ganglia/plugins/util.py";
		"/usr/lib/ganglia/python_modules/compat.py":
			source => "puppet:///files/ganglia/plugins/compat.py";
		"/etc/ganglia/conf.d/htcpseqcheck.pyconf":
			require => File["/etc/ganglia/conf.d"],
			source => "puppet:///files/ganglia/plugins/htcpseqcheck.pyconf";
        }
}

# TODO: Create a generic udp2log parameterized class and use it for this, and
# for misc::mediawiki-logger above
class misc::udp2log::aft {
	
	# TODO: add system_role

	file {
		"/etc/init.d/udp2log-aft":
			mode => 0555,
			owner => root,
			group => root,
			source => "puppet:///files/udp2log/udp2log-aft";
	}

	service {
		"udp2log-aft":
			ensure => running,
			enable => true,
			require => File["/etc/init.d/udp2log-aft"];
	}

}

# CI test server as per RT #1204
class misc::contint::test {

	system_role { "misc::contint::test": description => "continuous integration test server" }

	# split up packages into groups a bit for readability and flexibility ("ensure present" vs. "ensure latest" ?)

	$CI_PHP_packages = [ "libapache2-mod-php5", "php-apc", "php5-cli", "php5-curl", "php5-gd", "php5-intl", "php5-mysql", "php-pear", "php5-sqlite", "php5-tidy" ]
	$CI_DB_packages  = [ "mysql-server", "sqlite3" ]
	$CI_DEV_packages = [ "ant", "git-core", "imagemagick", "subversion" ]

	package { $CI_PHP_packages:
		ensure => present;
	}

	package { $CI_DB_packages:
		ensure => present;
	}

	package { $CI_DEV_packages:
		ensure => present;
	}
	
	# Prefer the PHP package from Ubuntu
	generic::apt::pin-package { [ libapache2-mod-php5, php5-common, php5-tidy, php5-intl ]: }

	# first had code here to add the jenkins repo and key, but this package should be added to our own repo instead
	# package { "jenkins":
	#	ensure => present,
	#	require => File["jenkins.list"],
	#}

	service { 'jenkins':
		enable => true,
		ensure => 'running',
		hasrestart => true,
		start => '/etc/init.d/jenkins start',
		stop => '/etc/init.d/jenkins stop';
	}

	# nagios monitoring
	monitor_service { "jenkins": description => "jenkins_service_running", check_command => "check_jenkins_service" }

	file {
		# Top level jobs folder
		"/var/lib/jenkins/jobs/":
			owner => "jenkins",
			group => "wikidev",
			mode => 0775,
			ensure => directory;
		# The following are for the main project: MediaWiki-phpunit
		"/var/lib/jenkins/jobs/MediaWiki-phpunit":
			owner => "jenkins",
			group => "wikidev",
			mode => 0775,
			ensure => directory;
		"/var/lib/jenkins/jobs/MediaWiki-phpunit/build.properties":
			owner => jenkins,
			group => wikidev,
			mode => 0555,
			source => "puppet:///files/misc/jenkins/jobs/MediaWiki-phpunit/build.properties";
		"/var/lib/jenkins/jobs/MediaWiki-phpunit/build.xml":
			owner => jenkins,
			group => wikidev,
			mode => 0555,
			source => "puppet:///files/misc/jenkins/jobs/MediaWiki-phpunit/build.xml";
		"/var/lib/jenkins/jobs/MediaWiki-phpunit/config.xml":
			owner => jenkins,
			group => wikidev,
			mode => 0555,
			source => "puppet:///files/misc/jenkins/jobs/MediaWiki-phpunit/config.xml";
		"/var/lib/jenkins/jobs/MediaWiki-phpunit/ExtraSettings.php":
			owner => jenkins,
			group => wikidev,
			mode => 0555,
			source => "puppet:///files/misc/jenkins/jobs/MediaWiki-phpunit/ExtraSettings.php";
		# Let wikidev users maintain the homepage
		 "/srv/org":
				mode => 0755,
				owner => www-data,
				group => wikidev,
				ensure => directory;
		 "/srv/org/mediawiki":
				mode => 0755,
				owner => www-data,
				group => wikidev,
				ensure => directory;
		 "/srv/org/mediawiki/integration":
				mode => 0755,
				owner => www-data,
				group => wikidev,
				ensure => directory;
		"/srv/org/mediawiki/integration/index.html":
			owner => www-data,
			group => wikidev,
			mode => 0555,
			source => "puppet:///files/misc/jenkins/index.html";
	}

	# run jenkins behind Apache and have pretty URLs / proxy port 80
	# https://wiki.jenkins-ci.org/display/JENKINS/Running+Jenkins+behind+Apache

	apache_module { proxy: name => "proxy" }
	apache_module { proxy_http: name => "proxy_http" }
	apache_site { integration: name => "integration.mediawiki.org" }

	file {
		"/etc/default/jenkins":
			owner => "root",
			group => "root",
			mode => 0444,
			source => "puppet:///files/misc/jenkins/etc_default_jenkins";
		"/etc/apache2/conf.d/jenkins_proxy":
			owner => "root",
			group => "root",
			mode => 0444,
			source => "puppet:///files/misc/jenkins/apache_proxy";
	}		

	# prevent users from accessing port 8080 directly (but still allow from localhost and own net)

	class iptables-purges {

		require "iptables::tables"

		iptables_purge_service{  "deny_all_http-alt": service => "http-alt" }
	}

	class iptables-accepts {

		require "misc::contint::test::iptables-purges"

		iptables_add_service{ "lo_all": interface => "lo", service => "all", jump => "ACCEPT" }
		iptables_add_service{ "localhost_all": source => "127.0.0.1", service => "all", jump => "ACCEPT" }
		iptables_add_service{ "private_all": source => "10.0.0.0/8", service => "all", jump => "ACCEPT" }
		iptables_add_service{ "public_all": source => "208.80.154.128/26", service => "all", jump => "ACCEPT" }
	}

	class iptables-drops {

		require "misc::contint::test::iptables-accepts"

		iptables_add_service{ "deny_all_http-alt": service => "http-alt", jump => "DROP" }
	}

	class iptables {

		require "misc::contint::test::iptables-drops"

		iptables_add_exec{ "${hostname}": service => "http-alt" }
	}
	
	require "misc::contint::test::iptables"
}
