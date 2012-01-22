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
		file { "/srv/autoinstall":
			mode => 0555,
			owner => root,
			group => root,
			path => "/srv/autoinstall/",
			source => "puppet:///files/autoinstall",
			recurse => true,
			links => manage
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

class misc::noc-wikimedia {
	system_role { "misc::noc-wikimedia": description => "noc.wikimedia.org" }
	
	package { [ "apache2", "libapache2-mod-php5" ]:
		ensure => latest;
	}

	include passwords::ldap::wmf_cluster
	$proxypass = $passwords::ldap::wmf_cluster::proxypass

	file {
		"/etc/apache2/sites-available/noc.wikimedia.org":
			require => [ Apache_module[userdir], Apache_module[cgi], Package[libapache2-mod-php5] ],
			path => "/etc/apache2/sites-available/noc.wikimedia.org",
			mode => 0444,
			owner => root,
			group => root,
			source => "puppet:///files/apache/sites/noc.wikimedia.org";
		"/etc/apache2/sites-available/graphite.wikimedia.org":
			path => "/etc/apache2/sites-available/graphite.wikimedia.org",
			content => template('apache/sites/graphite.wikimedia.org'),
			mode => 0444,
			owner => root,
			group => root;
		"/usr/lib/cgi-bin":
			source => "puppet:///files/cgi-bin/noc/",
			recurse => true,
			ignore => ".svn",
			ensure => present;
	}

	apache_module { userdir: name => "userdir" }
	apache_module { cgi: name => "cgi" }
	apache_module { ldap: name => "ldap" }
	apache_module { authnz_ldap: name => "authnz_ldap" }
	apache_module { proxy: name => "proxy" }
	apache_module { proxy_http: name => "proxy_http" }
	apache_module { ssl: name => "ssl" }

	apache_site { noc: name => "noc.wikimedia.org" }
	apache_site { graphiteproxy: name => "graphite.wikimedia.org" }

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

	require apaches::packages,
		generic::php5-gd
	
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

	generic::apt::pin-package { [ "squid", "squid-common" ]: }

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
		"/etc/sysctl.d/99-big-rmem.conf":
			owner => "root",
			group => "root",
			mode => 0444,
			content => "
net.core.rmem_max = 536870912
";
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
		command => "php /home/wikipedia/common/php/extensions/ExtensionDistributor/cron.php 2>&1 >/dev/null",
		environment => "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
		hour => 3,
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

	lighttpd_config { "10-rt": 
		require => [ Package["request-tracker3.8"], File["/etc/lighttpd/conf-available/10-rt.conf"] ],
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

class misc::etherpad_lite {

	include misc::apache2,
		passwords::etherpad_lite

	$etherpad_db_pass = $passwords::etherpad_lite::etherpad_db_pass

	if $realm == "labs" {
		$etherpad_host = $fqdn
		$etherpad_ssl_cert = "/etc/ssl/certs/ssl-cert-snakeoil.pem"
		$etherpad_ssl_key = "/etc/ssl/private/ssl-cert-snakeoil.key"
	}

	system_role { "misc::etherpad_lite": description => "Etherpad-lite server" }

	file {
		"/etc/apache2/sites-available/etherpad.wikimedia.org":
			mode => 444,
			owner => root,
			group => root,
			notify => Service["apache2"],
			content => template('apache/sites/etherpad_lite.wikimedia.org.erb'),
			ensure => present;
	}

	apache_site { controller: name => "etherpad.wikimedia.org" }
	apache_module { rewrite: name => "rewrite" }
	apache_module { proxy: name => "proxy" }
	apache_module { proxy_http: name => "proxy_http" }
	apache_module { ssl: name => "ssl" }

	package { etherpad-lite:
		ensure => latest;
	}
	service { etherpad-lite:
		require => Package["etherpad-lite"],
		subscribe => File['/etc/etherpad-lite/settings.json'],
		enable => true,
		ensure => running;
	}
	service { apache2:
		enable => true,
		ensure => running;
	}

	file {
		'/etc/etherpad-lite/settings.json':
			require => Package[etherpad-lite],
			owner => 'root',
			group => 'root',
			mode => 0444,
			content => template('etherpad_lite/settings.json.erb');
		'/etc/apache2/sites-enabled/000-default':
			notify => Service["apache2"],
			require => Package["apache2"],
			ensure => absent;
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

	if ( $realm == 'production' ) {
		user { jenkins:
			name => "jenkins",
			groups => [ "wikidev" ]; 
		}
	}
	
	service { 'jenkins':
		enable => true,
		ensure => 'running',
		hasrestart => true,
		start => '/etc/init.d/jenkins start',
		stop => '/etc/init.d/jenkins stop';
	}

	# Nagios monitoring
	monitor_service { "jenkins": description => "jenkins_service_running", check_command => "check_procs_generic!1!3!1!20!jenkins" }

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

	package { [ "libapache2-mod-php5", "php5-cli", "php-pear", "php5-common", "php5-curl", "php5-dev", "php5-gd", "php5-mysql", "php5-sqlite", "subversion", "mysql-client-5.1", "phpunit", "dovecot-imapd", "exim4-daemon-heavy", "exim4-config", "python-scipy", "python-matplotlib", "python-libxml2", "python-sqlite", "python-sqlitecachec", "python-urlgrabber", "python-argparse", "python-dev", "python-setuptools", "python-mysqldb", "libapache2-mod-python" ]:
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
		"/opt/fundraising-misc/auditing/paypal-audit/auth.cfg":
			mode => 0444,
			owner => www-data,
			group => wikidev,
			source => "puppet:///private/misc/fundraising/fundraising-misc.auth.cfg";
		"/opt/fundraising-misc/public_reporting/update_config.php":
			mode => 0444,
			owner => root,
			group => root,
			source => "puppet:///private/misc/fundraising/fundraising-misc.update_config.php";
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
		"/etc/php5/apache2/php.ini":
			mode => 0444,
			owner => root,
			group => root,
			source => "puppet:///private/php/php.ini.civicrm";
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

		"/etc/exim4/wikimedia.org-fundraising-private.key":
			mode => 0440,
			owner => root,
			group => Debian-exim,
			source => "puppet:///private/dkim/wikimedia.org-fundraising-private.key";

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
		"/usr/local/bin/collect_exim_stats_via_gmetric":
			source => "puppet:///files/ganglia/collect_exim_stats_via_gmetric",
			mode => 0755,
			owner => root,
			group => root;

		# other stuff
		"/etc/php5/cli/php.ini":
			mode => 0444,
			owner => root,
			group => root,
			source => "puppet:///private/php/php.ini.fundraising.cli";
		"/usr/local/bin/civimail_send":
			mode => 0710,
			owner => root,
			group => wikidev,
			source => "puppet:///private/misc/fundraising/civimail_send";
		"/usr/local/bin/jenkins_watcher":
			mode => 0500,
			owner => root,
			group => root,
			source => "puppet:///private/misc/fundraising/jenkins_watcher";
		"/usr/local/bin/jenkins_archiver":
			mode => 0500,
			owner => root,
			group => root,
			source => "puppet:///private/misc/fundraising/jenkins_archiver";
		"/usr/local/bin/sync_archive_to_storage3":
			mode => 0500,
			owner => root,
			group => root,
			source => "puppet:///private/misc/fundraising/sync_archive_to_storage3";
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

	require mysql::client
	package { [ "libapache2-mod-php5", "php5-cli", "php-pear", "php5-common", "php5-gd", "php5-mysql" ]:
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
	
	system_role { "misc::download-mediawiki": description => "MediaWiki download" }

	# FIXME: require apache

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

	apache_site { "download.mediawiki.org": name => "download.mediawiki.org" }
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
		"/etc/logrotate.d/aft-udp2log":
			mode => 0444,
			source => "puppet:///files/logrotate/aft-udp2log";
	}

	service {
		"udp2log-aft":
			ensure => running,
			enable => true,
			require => File["/etc/init.d/udp2log-aft"];
	}

}
# TODO: this is  a hacky short term method to get the config files into
#       puppet.  The app should be puppetized for real using mediawiki-logger above.
class misc::udp2log::lockeconfig {
	include contacts::udp2log
	file {
		"/etc/udp2log/squid":
			mode => 644,
			owner => root,
			group => root,
			content => template("udp2log/locke-etc-squid.erb");
	}
}
class misc::udp2log::emeryconfig {
	include contacts::udp2log
	file {
		"/etc/udp2log/locke-filters":
			mode => 644,
			owner => root,
			group => root,
			content => template("udp2log/emery-etc-locke-filters.erb");
	}
}


# CI test server as per RT #1204
class misc::contint::test {

	system_role { "misc::contint::test": description => "continuous integration test server" }

	class packages {
		# split up packages into groups a bit for readability and flexibility ("ensure present" vs. "ensure latest" ?)

		require generic::webserver::php5

		$CI_PHP_packages = [ "php-apc", "php5-cli", "php5-curl", "php5-gd", "php5-intl", "php5-mysql", "php-pear", "php5-sqlite", "php5-tidy", "php5-pgsql" ]
		$CI_DB_packages  = [ "mysql-server", "sqlite3", "postgresql" ]
		$CI_DEV_packages = [ "ant", "imagemagick" ]

		package { $CI_PHP_packages:
			ensure => present;
		}

		package { $CI_DB_packages:
			ensure => present;
		}

		package { $CI_DEV_packages:
			ensure => present;
		}

		include svn::client

		include generic::packages::git-core

		# Prefer the PHP packages from Ubuntu
		generic::apt::pin-package { $CI_PHP_packages: }

	}

	class virtualhost {
		# Common apache configuration. Setup integration.mediawiki.org
		apache_module { ssl: name => "ssl" }
		apache_site { integration: name => "integration.mediawiki.org" }

		file {
			# Placing the file in sites-available
			"/etc/apache2/sites-available/integration.mediawiki.org":
				path => "/etc/apache2/sites-available/integration.mediawiki.org",
				mode => 0444,
				owner => root,
				group => root,
				source => "puppet:///files/apache/sites/integration.mediawiki.org";

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

		# Reload apache whenever apache configuration change
		exec {	"reload-apache-on-integration-change":
			command => "/usr/sbin/service apache2 reload",
			subscribe => File['/etc/apache2/sites-available/integration.mediawiki.org'],
			refreshonly => true,
			onlyif => "/usr/sbin/apache2ctl configtest"
		}
	}

	class jenkins {
		require misc::contint::test::virtualhost

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
		}

		# run jenkins behind Apache and have pretty URLs / proxy port 80
		# https://wiki.jenkins-ci.org/display/JENKINS/Running+Jenkins+behind+Apache

		apache_module { proxy: name => "proxy" }
		apache_module { proxy_http: name => "proxy_http" }

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
	}

	class testswarm {
		require misc::contint::test::virtualhost

		# Testswarm is configured using the debian package
		package { testswarm: ensure => latest; }

		# Create a user to run the cronjob with
		systemuser { testswarm:
			name  => "testswarm",
			home  => "/var/lib/testswarm",
			shell => "/bin/bash",
			# And part of web server user group so we can let it access
			# the SQLite databases
			groups => [ 'www-data' ];
		}

		# install scripts
		file {
			"/etc/testswarm/fetcher-sample.ini":
				require => [
					Systemuser[testswarm],
					Package["testswarm"]
				],
				source  => "puppet:///files/testswarm/fetcher-sample.ini",
				mode    => 0660,
				owner   => testswarm,
				group   => testswarm;
			"/var/lib/testswarm/script":
				require => Systemuser[testswarm],
				ensure  => directory,
				owner   => testswarm,
				group   => testswarm;
			"/var/lib/testswarm/script/testswarm-mw-fetcher-run.php":
				require => Systemuser[testswarm],
				ensure  => present,
				source  => "puppet:///files/testswarm/testswarm-mw-fetcher-run.php",
				owner   => testswarm,
				group   => testswarm;
			"/var/lib/testswarm/script/testswarm-mw-fetcher.php":
				require => Systemuser[testswarm],
				ensure  => present,
				source  => "puppet:///files/testswarm/testswarm-mw-fetcher.php",
				owner   => testswarm,
				group   => testswarm;
			# Directory that hold the mediawiki fetches
			"/var/lib/testswarm/mediawiki-trunk":
				require => Systemuser[testswarm],
				ensure  => directory,
				owner   => testswarm,
				group   => testswarm;
			# SQLite databases files need specific user rights
			"/var/lib/testswarm/mediawiki-trunk/dbs":
				require => Systemuser[testswarm],
				ensure  => directory,
				mode    => 0774,
				owner   => testswarm,
				group   => www-data;
			# Override Apache configuration coming from the testswarm package.
			"/etc/apache2/conf.d/testswarm.conf":
				ensure => absent;
		}

		# Finally setup cronjob to fetch our files and setup a MediaWiki instance
		cron {
			testswarm-fetcher-mw-trunk:
				command => "(cd /var/lib/testswarm; php script/testswarm-mw-fetcher-run.php --prod) >> mediawiki-trunk/cron.log 2>&1",
				user => testswarm,
				require => Systemuser[testswarm],
				ensure => present;
		}

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

class misc::udpprofile::collector {
	system_role { "misc::udpprofile::collector": description => "MediaWiki UDP profile collector" }

	package { "udpprofile":
		ensure => latest;
	}

	service { udpprofile:
		require => Package[ 'udpprofile' ],
		ensure => running;
	}

	# FIXME: Nagios monitoring
}

class misc::graphite { 
	system_role { "misc::graphite": description => "graphite and carbon services" }

	include misc::apache2

	package { [ "python-libxml2", "python-sqlite", "python-sqlitecachec", "python-setuptools", "libapache2-mod-python", "libcairo2", "python-cairo", "python-simplejson", "python-django", "python-django-tagging", "python-twisted", "python-twisted-runner", "python-twisted-web", "memcached", "python-memcache" ]:
		ensure => present;
	}

	package { [ "python-carbon", "python-graphite-web", "python-whisper" ]:
		ensure => "0.9.9-1";
	}

	file { 
		"/etc/apache2/sites-available/graphite":
			owner => "root",
			group => "root",
			mode => 0444,
			source => "puppet:///files/graphite/apache.conf";
		"/a/graphite/conf/carbon.conf":
			owner => "root",
			group => "root",
			mode => 0444,
			source => "puppet:///files/graphite/carbon.conf";
		"/a/graphite/conf/dashboard.conf":
			owner => "root",
			group => "root",
			mode => 0444,
			source => "puppet:///files/graphite/dashboard.conf";
		"/a/graphite/conf/storage-schemas.conf":
			owner => "root",
			group => "root",
			mode => 0444,
			source => "puppet:///files/graphite/storage-schemas.conf";
		"/a/graphite/storage":
			owner => "www-data",
			group => "www-data",
			mode => 0755,
			ensure => directory;
		"/etc/sysctl.d/99-big-rmem.conf":
			owner => "root",
			group => "root",
			mode => 0444,
			content => "
net.core.rmem_max = 536870912
net.core.rmem_default = 536870912
";
	}

	apache_module { python: name => "python" }
	apache_site { graphite: name => "graphite" }
}

class misc::scripts {
	require misc::passwordScripts

	# scap requires sync-common, which is in the wikimedia-task-appserver package
	require mediawiki::packages

	# TODO: Should this be in a package instead, maybe? It's conceptually nicer than keeping scripts in the puppet git repo,
	# but rebuilding packages isn't as easy as updating a file through this mechanism, right?

	file {
		"/usr/local/bin/clear-profile":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/misc/scripts/clear-profile";
		"/usr/local/bin/configchange":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/misc/scripts/configchange";
		"/usr/local/bin/dologmsg":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/misc/scripts/dologmsg";
		"/usr/local/bin/deploy2graphite":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/misc/scripts/deploy2graphite";
		"/usr/local/bin/fatalmonitor":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/misc/scripts/fatalmonitor";
		"/usr/local/bin/foreachwiki":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/misc/scripts/foreachwiki";
		"/usr/local/bin/foreachwikiindblist":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/misc/scripts/foreachwikiindblist";
		"/usr/local/bin/lint":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/misc/scripts/lint";
		"/usr/local/bin/lint.php":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/misc/scripts/lint.php";
		"/usr/local/bin/mwscript":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/misc/scripts/mwscript";
		"/usr/local/bin/mwscriptwikiset":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/misc/scripts/mwscriptwikiset";
		"/usr/local/bin/mwversionsinuse":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/misc/scripts/mwversionsinuse";
		"/usr/local/bin/notifyNewProjects":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/misc/scripts/notifyNewProjects";
		"/usr/local/bin/purge-checkuser": # FIXME this is for a hume cronjob. Should puppetize the cronjob and move this to another class
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/misc/scripts/purge-checkuser";
		"/usr/local/bin/purge-varnish":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/misc/scripts/purge-varnish";
		"/usr/local/bin/refreshWikiversionsCDB":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/misc/scripts/refreshWikiversionsCDB";
		"/usr/local/bin/reset-mysql-slave":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/misc/scripts/reset-mysql-slave";
		"/usr/local/bin/scap":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/misc/scripts/scap";
		"/usr/local/bin/set-group-write":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/misc/scripts/set-group-write";
		"/usr/local/bin/sql":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/misc/scripts/sql";
		"/usr/local/bin/sync-apache":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/misc/scripts/sync-apache";
		"/usr/local/bin/sync-apache-simulated":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/misc/scripts/sync-apache-simulated";
		"/usr/local/bin/sync-common-all":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/misc/scripts/sync-common-all";
		"/usr/local/bin/sync-common-file":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/misc/scripts/sync-common-file";
		"/usr/local/bin/sync-dblist":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/misc/scripts/sync-dblist";
		"/usr/local/bin/sync-dir":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/misc/scripts/sync-dir";
		"/usr/local/bin/sync-docroot":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/misc/scripts/sync-docroot";
		"/usr/local/bin/sync-file":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/misc/scripts/sync-file";
		"/usr/local/bin/sync-wikiversions":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/misc/scripts/sync-wikiversions";
		"/usr/local/bin/udprec":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/misc/scripts/udprec";
		"/usr/local/bin/update-special-pages": # FIXME hume cron job
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/misc/scripts/update-special-pages";
		"/usr/local/bin/update-special-pages-small": # FIXME hume cron job
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/misc/scripts/update-special-pages-small";
		"/usr/local/sbin/set-group-write2":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/misc/scripts/set-group-write2";
	}
}

class misc::passwordScripts {
	include passwords::misc::scripts
	$cachemgr_pass = $passwords::misc::scripts::cachemgr_pass
	$mysql_root_pass = $passwords::misc::scripts::mysql_root_pass
	$nagios_sql_pass = $passwords::misc::scripts::nagios_sql_pass
	$webshop_pass = $passwords::misc::scripts::webshop_pass
	$wikiadmin_pass = $passwords::misc::scripts::wikiadmin_pass
	$wikiuser2_pass = $passwords::misc::scripts::wikiuser2_pass
	$wikiuser_pass = $passwords::misc::scripts::wikiuser_pass
	$wikiuser_pass_nagios = $passwords::misc::scripts::wikiuser_pass_nagios
	$wikiuser_pass_real = $passwords::misc::scripts::wikiuser_pass_real

	file {
		"/usr/local/bin/cachemgr_pass":
			owner => root,
			group => wikidev,
			mode => 0550,
			content => template("misc/passwordScripts/cachemgr_pass.erb");
		"/usr/local/bin/mysql_root_pass":
			owner => root,
			group => wikidev,
			mode => 0550,
			content => template("misc/passwordScripts/mysql_root_pass.erb");
		"/usr/local/bin/nagios_sql_pass":
			owner => root,
			group => wikidev,
			mode => 0550,
			content => template("misc/passwordScripts/nagios_sql_pass.erb");
		"/usr/local/bin/webshop_pass":
			owner => root,
			group => wikidev,
			mode => 0550,
			content => template("misc/passwordScripts/webshop_pass.erb");
		"/usr/local/bin/wikiadmin_pass":
			owner => root,
			group => wikidev,
			mode => 0550,
			content => template("misc/passwordScripts/wikiadmin_pass.erb");
		"/usr/local/bin/wikiuser2_pass":
			owner => root,
			group => wikidev,
			mode => 0550,
			content => template("misc/passwordScripts/wikiuser2_pass.erb");
		"/usr/local/bin/wikiuser_pass":
			owner => root,
			group => wikidev,
			mode => 0550,
			content => template("misc/passwordScripts/wikiuser_pass.erb");
		"/usr/local/bin/wikiuser_pass_nagios":
			owner => root,
			group => wikidev,
			mode => 0550,
			content => template("misc/passwordScripts/wikiuser_pass_nagios.erb");
		"/usr/local/bin/wikiuser_pass_real":
			owner => root,
			group => wikidev,
			mode => 0550,
			content => template("misc/passwordScripts/wikiuser_pass_real.erb");
	}
}

class misc::udp2log::packetloss {
	package { "ganglia-logtailer":
		ensure => latest;
	}
	file {
		"PacketLossLogtailer.py":
			path => "/usr/share/ganglia-logtailer/PacketLossLogtailer.py",
			mode => 0444,
			owner => root,
			group => root,
			source => "puppet:///files/misc/PacketLossLogtailer.py";
	}
}

class misc::udp2log::emery {
# emery and locke have their log files in different places and therefore need different cron jobs
	cron { "ganglia-logtailer" :
		ensure => present,
		command => "/usr/sbin/ganglia-logtailer --classname PacketLossLogtailer --log_file /var/log/squid/packet-loss.log --mode cron",
		user => 'root',
		minute => '*/5';
	}

	monitor_service { "packetloss": description => "Packetloss_Average", check_command => "check_packet_loss_ave!4!8" }
}
class misc::udp2log::locke {
# emery and locke have their log files in different places and therefore need different cron jobs
	cron { "ganglia-logtailer" :
		ensure => present,
		command => "/usr/sbin/ganglia-logtailer --classname PacketLossLogtailer --log_file /a/squid/packet-loss.log --mode cron",
		user => 'root',
		minute => '*/5';
	}
	monitor_service { "packetloss": description => "Packetloss_Average", check_command => "check_packet_loss_ave!4!8" }
}
class misc::l10nupdate {
	require misc::scripts

	cron {
		l10nupdate:
			command => "/usr/local/bin/l10nupdate-1 >> /var/log/l10nupdatelog/l10nupdate.log 2>&1",
			user => l10nupdate,
			hour => 2,
			minute => 0,
			ensure => present;
	}

	file {
		"/usr/local/bin/l10nupdate":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/misc/l10nupdate/l10nupdate";
		"/usr/local/bin/l10nupdate-1":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/misc/l10nupdate/l10nupdate-1";
		"/usr/local/bin/l10nupdate-2":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/misc/l10nupdate/l10nupdate-2";
		"/usr/local/bin/l10nupdate-3":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/misc/l10nupdate/l10nupdate-3";
		"/usr/local/bin/sync-l10nupdate":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/misc/l10nupdate/sync-l10nupdate";
		"/usr/local/bin/sync-l10nupdate-1":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/misc/l10nupdate/sync-l10nupdate-1";
	}

	# Make sure the log directory exists and has adequate permissions.
	# It's called l10nupdatelog because /var/log/l10nupdate was used
	# previously so it'll be an existing file on some systems.
	# Also create the dir for the SVN checkouts, and set up log rotation
	file {
		"/var/log/l10nupdatelog/":
			owner => l10nupdate,
			group => wikidev,
			mode => 0664,
			ensure => directory;
		"/var/lib/l10nupdate":
			owner => l10nupdate,
			group => wikidev,
			mode => 0755,
			ensure => directory;
		"/etc/logrotate.d/l10nupdate":
			source => "puppet:///files/logrotate/l10nupdate",
			mode => 0444;
	}
}

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

# FIXME: (increasingly popular) temporary hack
if $hostname == "spence" {
        include misc::gsbmonitoring
}

class misc::gsbmonitoring {
	@monitor_host { "google": ip_address => "74.125.225.84" }

	@monitor_service { "GSB_mediawiki": description => "check google safe browsing for mediawiki.org", check_command => "check_http_url_for_string!www.google.com!/safebrowsing/diagnostic?site=mediawiki.org/!'This site is not currently listed as suspicious'", host => "google" }
	@monitor_service { "GSB_wikibooks": description => "check google safe browsing for wikibooks.org", check_command => "check_http_url_for_string!www.google.com!/safebrowsing/diagnostic?site=wikibooks.org/!'This site is not currently listed as suspicious'", host => "google" }
	@monitor_service { "GSB_wikimedia": description => "check google safe browsing for wikimedia.org", check_command => "check_http_url_for_string!www.google.com!/safebrowsing/diagnostic?site=wikimedia.org/!'This site is not currently listed as suspicious'", host => "google" }
	@monitor_service { "GSB_wikinews": description => "check google safe browsing for wikinews.org", check_command => "check_http_url_for_string!www.google.com!/safebrowsing/diagnostic?site=wikinews.org/!'This site is not currently listed as suspicious'", host => "google" }
	@monitor_service { "GSB_wikipedia": description => "check google safe browsing for wikipedia.org", check_command => "check_http_url_for_string!www.google.com!/safebrowsing/diagnostic?site=wikipedia.org/!'This site is not currently listed as suspicious'", host => "google" }
	@monitor_service { "GSB_wikiquotes": description => "check google safe browsing for wikiquotes.org", check_command => "check_http_url_for_string!www.google.com!/safebrowsing/diagnostic?site=wikiquotes.org/!'This site is not currently listed as suspicious'", host => "google" }
	@monitor_service { "GSB_wikisource": description => "check google safe browsing for wikisource.org", check_command => "check_http_url_for_string!www.google.com!/safebrowsing/diagnostic?site=wikisource.org/!'This site is not currently listed as suspicious'", host => "google" }
	@monitor_service { "GSB_wikiversity": description => "check google safe browsing for wikiversity.org", check_command => "check_http_url_for_string!www.google.com!/safebrowsing/diagnostic?site=wikiversity.org/!'This site is not currently listed as suspicious'", host => "google" }
	@monitor_service { "GSB_wiktionary": description => "check google safe browsing for wiktionary.org", check_command => "check_http_url_for_string!www.google.com!/safebrowsing/diagnostic?site=wiktionary.org/!'This site is not currently listed as suspicious'", host => "google" }
}


class misc::bugzilla::crons {
	cron { bugzilla_whine:
		command => "cd /srv/org/wikimedia/bugzilla/ ; ./whine.pl",
		user => root,
		minute => 15
	}

	# 2 cron jobs to generate charts data
	# See https://bugzilla.wikimedia.org/29203
	# 1) get statistics for the day:
	cron { bugzilla_collectstats:
		command => "cd /srv/org/wikimedia/bugzilla/ ; ./collectstats.pl",
		user    => root,
		hour    => 0,
		minute  => 5,
		weekday => [ 1, 2, 3, 4, 5, 6 ] # Monday - Saturday
	}
	# 2) on sunday, regenerates the whole statistics data
	cron { bugzilla_collectstats_regenerate:
		command => "cd /srv/org/wikimedia/bugzilla/ ; ./collectstats.pl --regenerate",
		user    => root,
		hour    => 0,
		minute  => 5,
		weekday => 0  # Sunday
	}
}

class misc::package-builder {
	system_role { "misc::package-builder": description => "Debian package builder" }
	
	include generic::packages::git-core
	
	class packages {
		package { [ "build-essential", "fakeroot", "debhelper", "git-buildpackage", "dupload", "libio-socket-ssl-perl" ]:
			ensure => latest;
		}
	}
	
	class defaults {
		File { mode => 0444 }
		
		file {
			"/etc/devscripts.conf":
				content => template("misc/devscripts.conf.erb");
			"/etc/git-buildpackage/gbp.conf":
				require => Package["git-buildpackage"],
				content => template("misc/gbp.conf.erb");
			"/etc/dupload.conf":
				require => Package["dupload"],
				content => template("misc/dupload.conf.erb");
		}
	}
	
	include packages, defaults
}

class misc::ircecho {

	# To use this class, you must define some variables; here's an example:
	#  $ircecho_infile = "/var/log/nagios/irc.log"
	#  $ircecho_nick = "nagios-wm"
	#  $ircecho_chans = "#wikimedia-operations,#wikimedia-tech"
	#  $ircecho_server = "irc.freenode.net"

	package { "ircecho":
		ensure => latest;
	}

	service { "ircecho":
		require => Package[ircecho],
		ensure => running;
	}

	file {
		"/etc/default/ircecho":
			require => Package[ircecho],
			content => template('ircecho/default.erb'),
			owner => root,
			mode => 0755;
	}

}

class misc::racktables {
	# When this class is chosen, ensure that apache, php5-common, php5-mysql are 
	# installed on the host via another package set.

	system_role { "misc::racktables": description => "Racktables" }

	if $realm == "labs" {
		$racktables_host = "$instancename.${domain}"
		$racktables_ssl_cert = "/etc/ssl/certs/star.wmflabs.pem"
		$racktables_ssl_key = "/etc/ssl/private/star.wmflabs.key"
	} else {
		$racktables_host = "racktables.wikimedia.org"
		$racktables_ssl_cert = "/etc/ssl/certs/star.wikimedia.org.pem"
		$racktables_ssl_key = "/etc/ssl/private/star.wikimedia.org.key"
	}

	include generic::mysql::client,
		generic::php5-gd

	service { apache2:
		subscribe => Package[libapache2-mod-php5],
		ensure => running;
	}

	file {
		"/etc/apache2/sites-available/racktables.wikimedia.org":
		mode => 444,
		owner => root,
		group => root,
		notify => Service["apache2"],
		content => template('apache/sites/racktables.wikimedia.org.erb'),
		ensure => present;
	}

	apache_site { racktables: name => "racktables.wikimedia.org" }
	apache_confd { namevirtualhost: install => "true", name => "namevirtualhost" }
	apache_module { rewrite: name => "rewrite" }
	apache_module { ssl: name => "ssl" }
}

# http://planet.wikimedia.org/
class misc::planet {
	system_role { "misc::planet": description => "Planet weblog aggregator" }

	systemuser { planet: name => "planet", home => "/var/lib/planet", groups => [ "planet" ] }

	class {'generic::webserver::php5': ssl => 'true'; }

	file {
		"/etc/apache2/sites-available/planet.wikimedia.org":
			path => "/etc/apache2/sites-available/planet.wikimedia.org",
			mode => 0444,
			owner => root,
			group => root,
			source => "puppet:///files/apache/sites/planet.wikimedia.org";
	}

	apache_site { planet: name => "planet.wikimedia.org" }

	package { "python2.6":
		ensure => latest;
	}
}

# https://contacts.wikimedia.org | http://en.wikipedia.org/wiki/CiviCRM
class misc::civicrm {
	system_role { "misc::civicrm": description => "CiviCRM server" }

	class {'generic::webserver::php5': ssl => 'true'; }

	apache_site { contacts: name => "contacts.wikimedia.org" }
	apache_site { contacts-ssl: name => "contacts.wikimedia.org-ssl" }

	systemuser { civimail: name => "civimail", home => "/home/civimail", groups => [ "civimail" ] }
}
