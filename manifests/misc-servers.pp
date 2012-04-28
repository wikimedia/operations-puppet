# misc-servers.pp

# Resource definitions for miscellaneous servers

import "generic-definitions.pp"
import "nagios.pp"

class misc::noc-wikimedia {
	system_role { "misc::noc-wikimedia": description => "noc.wikimedia.org" }

	package { [ "apache2", "libapache2-mod-php5", "libapache2-mod-passenger", "libsinatra-ruby", "rails" ]:
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
		"/home/wikipedia/htdocs/noc/index.html":
			source => "puppet:///files/misc/noc/index.html",
			mode => 0664,
			owner => hashar,
			group => wikidev,
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
	monitor_service { "http": description => "HTTP", check_command => "check_http_url!noc.wikimedia.org!http://noc.wikimedia.org" }
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

        include generic::sysctl::high-bandwidth-rsync

	monitor_service { "lighttpd http": description => "Lighttpd HTTP", check_command => "check_http" }
	monitor_service { "nfs": description => "NFS", check_command => "check_tcp!2049" }
}

class misc::download-primary {
	system_role { "misc::download-primary": description => "Service for rsync to internal download mirrors" }

	package { rsync:
		ensure => latest;
	}

	file {
		"/etc/rsyncd.conf":
			require => Package[rsync],
			mode => 0444,
			owner => root,
			group => root,
			source => "puppet:///files/rsync/rsyncd.conf.downloadprimary";
		"/etc/default/rsync":
			require => Package[rsync],
			mode => 0444,
			owner => root,
			group => root,
			source => "puppet:///files/rsync/rsync.default.downloadprimary";
	}

	service { rsync:
		require => [ Package[rsync], File["/etc/rsyncd.conf"], File["/etc/default/rsync"] ],
		ensure => running;
	}
}

class misc::download-mirror {
	system_role { "misc::download-mirror": description => "Service for rsync to external download mirrors" }

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

class misc::apple-dictionary-bridge {
	system_role { "misc::apple-dictionary-bridge": description => "Apple Dictionary to API OpenSearch bridge" }

	require webserver::php5

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
		"/etc/apache2/sites-available/irc.wikimedia.org":
			mode => 0444,
			owner => root,
			group => root,
			source => "puppet:///files/apache/sites/irc.wikimedia.org";
	}

	# redirect http://irc.wikimedia.org to http://meta.wikimedia.org/wiki/IRC
	apache_site { irc: name => "irc.wikimedia.org" }
 
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

	require webserver::modproxy

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

	include webserver::apache2,
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
			mode => 0444,
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
			ensure => "/data/xmldatadumps/public/other/kiwix";
		"/data/xmldatadumps/public/other/kiwix":
			owner => "mirror",
			group => "mirror",
			mode => 0644,
			ensure => present;
	}

	cron { kiwix-mirror-update:
		command => "rsync -vzrlptD  download.kiwix.org::download.kiwix.org/zim/0.9/ /data/xmldatadumps/public/other/kiwix/zim/0.9/ >/dev/null 2>&1",
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
	monitor_service { "jenkins": description => "jenkins_service_running", check_command => "nrpe_check_jenkins" }

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

class misc::udpprofile::collector {
	system_role { "misc::udpprofile::collector": description => "MediaWiki UDP profile collector" }

	package { "udpprofile":
		ensure => latest;
	}

	service { udpprofile:
		require => Package[ 'udpprofile' ],
		ensure => running;
	}

	# Nagios monitoring (RT-2367)
	monitor_service { "carbon-cache": description => "carbon-cache.py", check_command => "nrpe_check_carbon_cache" }
	monitor_service { "profiler-to-carbon": description => "profiler-to-carbon", check_command => "nrpe_check_profiler_to_carbon" }
	monitor_service { "profiling collector": description => "profiling collector", check_command => "nrpe_check_profiling_collector" }

}

class misc::graphite {
	system_role { "misc::graphite": description => "graphite and carbon services" }

	include webserver::apache2

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
		"/a/graphite/conf/storage-aggregation.conf":
			owner => "root",
			group => "root",
			mode => 0444,
			source => "puppet:///files/graphite/storage-aggregation.conf";
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

	include network::constants

	varnish::instance { "graphite":
		name => "",
		vcl => "graphite",
		port => 81,
		admin_port => 6082,
		storage => "-s malloc,256M",
		backends => [ 'localhost' ],
		directors => { 'backend' => [ 'localhost' ] },
		vcl_config => {
			'retry5xx' => 0
		},
		backend_options => {
			'port' => 80,
			'connect_timeout' => "5s",
			'first_byte_timeout' => "35s",
			'between_bytes_timeout' => "4s",
			'max_connections' => 100,
			'probe' => "options",
		},
		enable_geoiplookup => "false",
		xff_sources => $network::constants::all_networks
	}
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
		"/var/log/l10nupdatelog":
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

class misc::mwfatallog {
	file {
		"/etc/logrotate.d/mwfatal":
			source => "puppet:///files/logrotate/mwfatal",
			owner => root,
			group => root,
			mode => 0444;
	}
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

	class {'webserver::php5': ssl => 'true'; }

	include generic::mysql::client,
		webserver::php5-gd

	file {
		"/etc/apache2/sites-available/racktables.wikimedia.org":
		mode => 0444,
		owner => root,
		group => root,
		notify => Service["apache2"],
		content => template('apache/sites/racktables.wikimedia.org.erb'),
		ensure => present;
	}

	apache_site { racktables: name => "racktables.wikimedia.org" }
	apache_confd { namevirtualhost: install => "true", name => "namevirtualhost" }
	apache_module { rewrite: name => "rewrite" }
}


# this is stupid but I need a firewall on iron so that mysql doesn't accidentally get exposed to the world.
class iron::iptables-purges {
	require "iptables::tables"
	# The deny_all rule must always be purged, otherwise ACCEPTs can be placed below it
	iptables_purge_service{ "iron_common_default_deny": service => "all" }
	# When removing or modifying a rule, place the old rule here, otherwise it won't
	# be purged, and will stay in the iptables forever
}
class iron::iptables-accepts {
	require "iron::iptables-purges"
	# Rememeber to place modified or removed rules into purges!
	# common services for all hosts
	iptables_add_rule{ "iron_common_established_tcp": table => "filter", chain => "INPUT", protocol => "tcp", accept_established => "true", jump => "ACCEPT" }
	iptables_add_rule{ "iron_common_established_udp": table => "filter", chain => "INPUT", protocol => "udp", accept_established => "true", jump => "ACCEPT" }
	iptables_add_service{ "iron_accept_all_private": service => "all", source => "10.0.0.0/8", jump => "ACCEPT" }
	iptables_add_service{ "iron_accept_all_localhost": service => "all", source => "127.0.0.0/8", jump => "ACCEPT" }
	iptables_add_service{ "iron_common_ssh": service => "ssh", source => "208.80.152.0/22", jump => "ACCEPT" }
	iptables_add_service{ "iron_ntp_udp": service => "ntp_udp", source => "208.80.152.0/22", jump => "ACCEPT" }
	iptables_add_service{ "iron_nrpe": service => "nrpe", source => "208.80.152.0/22", jump => "ACCEPT" }
	iptables_add_service{ "iron_gmond_tcp": service => "gmond_tcp", source => "208.80.152.0/22", jump => "ACCEPT" }
	iptables_add_service{ "iron_gmond_udp": service => "gmond_udp", destination => "239.192.0.0/16", jump => "ACCEPT" }
	iptables_add_service{ "iron_common_igmp": service => "igmp", jump => "ACCEPT" }
	iptables_add_service{ "iron_common_icmp": service => "icmp", jump => "ACCEPT" }
}
class iron::iptables-drops {
	require "iron::iptables-accepts"
	# Rememeber to place modified or removed rules into purges!
	iptables_add_service{ "iron_common_default_deny": service => "all", jump => "DROP" }
}
class iron::iptables  {
	# We use the following requirement chain:
	# iptables -> iptables::drops -> iptables::accepts -> iptables::purges
	#
	# This ensures proper ordering of the rules
	require "iron::iptables-drops"
	# This exec should always occur last in the requirement chain.
	iptables_add_exec{ "iron": service => "iron" }
}
