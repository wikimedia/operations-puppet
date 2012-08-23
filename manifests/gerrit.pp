# manifests/gerrit.pp
# Manifest to setup a Gerrit instance

class gerrit::instance($no_apache=false,
		$apache_ssl=false,
		$ircbot=false,
		$slave=false,
		$ssh_port="29418",
		$db_host="",
		$db_name="reviewdb",
		$host="",
		$db_user="gerrit") {

	include standard,
		gerrit::gitweb,
		gerrit::crons,
		role::ldap::config::labs

	group { "gerrit2":
		name => "gerrit2",
		ensure => present,
		allowdupe => false;
	}

	# Main config
	$sshport = $ssh_port
	$dbhost = $db_host
	$dbname = $db_name
	$dbuser = $db_user

	# Setup LDAP
	include role::ldap::config::labs
	$ldapconfig = $role::ldap::config::labs::ldapconfig

	$ldap_hosts = $ldapconfig["servernames"]
	$ldap_base_dn = $ldapconfig["basedn"]
	$ldap_proxyagent = $ldapconfig["proxyagent"]
	$ldap_proxyagent_pass = $ldapconfig["proxypass"]

	# Configure SSL for some hosts
	if $apache_ssl {
		$url = "https://${host}/r"
	}
	if !$apache_ssl {
		$url = "http://${host}/r"
	}

	# Common setup
	include gerrit::gerrit_config
	class {'gerrit::proxy':
		no_apache => $no_apache,
		apache_ssl => $apache_ssl
	}

	class {'gerrit::jetty':
		ldap_hosts => $ldap_hosts,
		ldap_base_dn => $ldap_base_dn,
		url => $url,
		dbhost => $dbhost,
		dbname => $dbname,
		hostname => $host,
		ldap_proxyagent => $ldap_proxyagent,
		ldap_proxyagent_pass => $ldap_proxyagent_pass,
		sshport => $sshport
	}

	# Optional modules
	if $ircbot { include gerrit::ircbot }
}

class gerrit::jetty ($ldap_hosts,
		$ldap_base_dn,
		$url,
		$dbhost,
		$dbname,
		$hostname,
		$sshport,
		$ldap_proxyagent,
		$ldap_proxyagent_pass) {
	system_role { "gerrit::jetty": description => "Wikimedia gerrit (git) server" }

	include gerrit::account,
		gerrit::crons,
		gerrit::gerrit_config,
		generic::packages::git-core

	package { [ "openjdk-6-jre", "git-svn" ]:
		ensure => latest;
	}

	package { [ "python-paramiko" ]:
		ensure => latest;
	}

	package { [ "gerrit" ]:
		ensure => "2.4.2-1";
	}

	file {
		"/etc/default/gerrit":
			source => "puppet:///files/gerrit/gerrit",
			owner => root,
			group => root,
			mode => 0444;
		"/var/lib/gerrit2/review_site":
			ensure => directory,
			owner => gerrit2,
			group => gerrit2,
			mode => 0755,
			require => Package["gerrit"];
		"/var/lib/gerrit2/review_site/etc":
			ensure => directory,
			owner => gerrit2,
			group => gerrit2,
			mode => 0755,
			require => File["/var/lib/gerrit2/review_site"];
		"/var/lib/gerrit2/review_site/etc/gerrit.config":
			content => template('gerrit/gerrit.config.erb'),
			owner => gerrit2,
			group => gerrit2,
			mode => 0444,
			require => File["/var/lib/gerrit2/review_site/etc"];
		"/var/lib/gerrit2/review_site/etc/secure.config":
			content => template('gerrit/secure.config.erb'),
			owner => gerrit2,
			group => gerrit2,
			mode => 0444,
			require => File["/var/lib/gerrit2/review_site/etc"];
		"/var/lib/gerrit2/review_site/etc/hookconfig.py":
			owner => gerrit2,
			group => gerrit2,
			mode => 0444,
			content => template('gerrit/hookconfig.py.erb'),
			require => File["/var/lib/gerrit2/review_site/etc"];
		"/var/lib/gerrit2/review_site/etc/mail/ChangeSubject.vm":
			owner => gerrit2,
			group => gerrit2,
			mode => 0444,
			source => "puppet:///files/gerrit/mail/ChangeSubject.vm",
			require => Exec["install_gerrit_jetty"];
		"/var/lib/gerrit2/review_site/etc/GerritSite.css":
			owner => gerrit2,
			group => gerrit2,
			mode => 0444,
			source => "puppet:///files/gerrit/skin/GerritSite.css";
		"/var/lib/gerrit2/review_site/etc/GerritSiteHeader.html":
			owner => gerrit2,
			group => gerrit2,
			mode => 0444,
			source => "puppet:///files/gerrit/skin/GerritSiteHeader.html";
		"/var/lib/gerrit2/review_site/static/page-bkg.jpg":
			owner => gerrit2,
			group => gerrit2,
			mode => 0444,
			source => "puppet:///files/gerrit/skin/page-bkg.jpg";
		"/var/lib/gerrit2/review_site/static/wikimedia-codereview-logo.png":
			owner => gerrit2,
			group => gerrit2,
			mode => 0444,
			source => "puppet:///files/gerrit/skin/wikimedia-codereview-logo.png";
		"/var/lib/gerrit2/review_site/hooks":
			owner => gerrit2,
			group => gerrit2,
			mode => 0755,
			ensure => directory,
			require => Exec["install_gerrit_jetty"];
		"/var/lib/gerrit2/review_site/hooks/change-abandoned":
			owner => gerrit2,
			group => gerrit2,
			mode => 0555,
			source => "puppet:///files/gerrit/hooks/change-abandoned",
			require => File["/var/lib/gerrit2/review_site/hooks"];
		"/var/lib/gerrit2/review_site/hooks/hookhelper.py":
			owner => gerrit2,
			group => gerrit2,
			mode => 0555,
			source => "puppet:///files/gerrit/hooks/hookhelper.py",
			require => File["/var/lib/gerrit2/review_site/hooks"];
		"/var/lib/gerrit2/review_site/hooks/change-merged":
			owner => gerrit2,
			group => gerrit2,
			mode => 0555,
			source => "puppet:///files/gerrit/hooks/change-merged",
			require => File["/var/lib/gerrit2/review_site/hooks"];
		"/var/lib/gerrit2/review_site/hooks/change-restored":
			owner => gerrit2,
			group => gerrit2,
			mode => 0555,
			source => "puppet:///files/gerrit/hooks/change-restored",
			require => File["/var/lib/gerrit2/review_site/hooks"];
		"/var/lib/gerrit2/review_site/hooks/comment-added":
			owner => gerrit2,
			group => gerrit2,
			mode => 0555,
			source => "puppet:///files/gerrit/hooks/comment-added",
			require => File["/var/lib/gerrit2/review_site/hooks"];
		"/var/lib/gerrit2/review_site/hooks/patchset-created":
			owner => gerrit2,
			group => gerrit2,
			mode => 0555,
			source => "puppet:///files/gerrit/hooks/patchset-created",
			require => File["/var/lib/gerrit2/review_site/hooks"];
	}

	exec {
		"install_gerrit_jetty":
			creates => "/var/lib/gerrit2/review_site/bin",
			user => "gerrit2",
			group => "gerrit2",
			cwd => "/var/lib/gerrit2",
			command => "/usr/bin/java -jar gerrit.war init -d review_site --batch --no-auto-start",
			require => [Package["gerrit"], File["/var/lib/gerrit2/review_site/etc/gerrit.config"]];
	}

	service {
		"gerrit":
			subscribe => File["/var/lib/gerrit2/review_site/etc/gerrit.config"],
			enable => true,
			ensure => running,
			hasstatus => false,
			status => "/etc/init.d/gerrit check",
			require => Exec["install_gerrit_jetty"];
	}

}

class gerrit::proxy( $no_apache = true, $apache_ssl = false ) {

	if !$no_apache {
		require webserver::apache
		apache_site { 000_default: name => "000-default", ensure => absent }
	}

	file {
		"/etc/apache2/sites-available/gerrit.wikimedia.org":
			mode => 0644,
			owner => root,
			group => root,
			source => "puppet:///files/apache/sites/gerrit.wikimedia.org",
			ensure => present;
	}

	apache_site { gerrit: name => "gerrit.wikimedia.org" }
	apache_module { rewrite: name => "rewrite" }
	apache_module { proxy: name => "proxy" }
	apache_module { proxy_http: name => "proxy_http" }
	if $apache_ssl {
		apache_module { ssl: name => "ssl" }
	}
}

class gerrit::gitweb {
	package { [ "gitweb" ]:
		ensure => latest;
	}

	file {
		# Overwrite gitweb's stupid default apache file
		"/etc/apache2/conf.d/gitweb":
			mode => 0444,
			owner => root,
			group => root,
			content => "Alias /gitweb /usr/share/gitweb",
			ensure => present,
			require => Package[gitweb];
		# Add our own customizations to gitweb
		"/var/lib/gerrit2/review_site/etc/gitweb_config.perl":
			mode => 0444,
			owner => root,
			group => root,
			source => "puppet:///files/gerrit/gitweb_config.perl",
			ensure => present,
			require => Package[gitweb];
		# Spiders make gitweb cry when they request tarballs
		"/var/www/robots.txt":
			mode => 0444,
			owner => root,
			group => root,
			source => "puppet:///files/misc/robots-txt-disallow",
			ensure => present;
	}
}

class gerrit::ircbot {

	include gerrit::gerrit_config

	$ircecho_infile = "/var/lib/gerrit2/review_site/logs/operations.log:#wikimedia-operations;/var/lib/gerrit2/review_site/logs/labs.log:#wikimedia-labs;/var/lib/gerrit2/review_site/logs/mobile.log:#wikimedia-mobile;/var/lib/gerrit2/review_site/logs/mediawiki.log:#mediawiki;/var/lib/gerrit2/review_site/logs/wikimedia-dev.log:#wikimedia-dev;/var/lib/gerrit2/review_site/logs/semantic-mediawiki.log:#semantic-mediawiki,#mediawiki;/var/lib/gerrit2/review_site/logs/wikidata.log:#wikimedia-wikidata,#mediawiki"
	$ircecho_nick = "gerrit-wm"
	$ircecho_chans = "#wikimedia-operations,#wikimedia-labs,#wikimedia-mobile,#mediawiki,#wikimedia-dev,#wikimedia-wikidata,#semantic-mediawiki"
	$ircecho_server = "irc.freenode.net"

	package { ['ircecho']:
		ensure => latest;
	}

	service { ['ircecho']:
		enable => true,
		ensure => running;
	}

	file {
		"/etc/default/ircecho":
			mode => 0444,
			owner => root,
			group => root,
			content => template('ircecho/default.erb'),
			notify => Service[ircecho],
			require => Package[ircecho];
	}
}

# Setup the `gerrit2` account for gerrit to run as
# The gerrit package already creates the user itself
class gerrit::account {

	ssh_authorized_key { gerrit2:
		key => "AAAAB3NzaC1yc2EAAAABIwAAAQEAxOlshfr3UaPr8gQ8UVskxHAGG9xb55xDyfqlK7vsAs/p+OXpRB4KZOxHWqI40FpHhW+rFVA0Ugk7vBK13oKCB435TJlHYTJR62qQNb2DVxi5rtvZ7DPnRRlAvdGpRft9JsoWdgsXNqRkkStbkA5cqotvVHDYAgzBnHxWPM8REokQVqil6S/yHkIGtXO5J7F6I1OvYCnG1d1GLT5nDt+ZeyacLpZAhrBlyFD6pCwDUhg4+H4O3HGwtoh5418U4cvzRgYOQQXsU2WW5nBQHE9LXVLoL6UeMYY4yMtaNw207zN6kXcMFKyTuF5qlF5whC7cmM4elhAO2snwIw4C3EyQgw==",
		type => "ssh-rsa",
		user => gerrit2,
		require => [Package["gerrit"],
				File["/var/lib/gerrit2/.ssh"]],
		ensure => present;
	}

	file {
		"/var/lib/gerrit2":
			mode  => 0600,
			owner => "gerrit2",
			ensure => directory;
		"/var/lib/gerrit2/.ssh":
			mode  => 0600,
			owner => "gerrit2",
			ensure => directory,
			require => File["/var/lib/gerrit2"];
		"/var/lib/gerrit2/.ssh/id_rsa":
			owner => gerrit2,
			group => gerrit2,
			mode  => 0600,
			require => [Package["gerrit"],
				Ssh_authorized_key["gerrit2"]],
			source => "puppet:///private/gerrit/id_rsa";
	}

}

class gerrit::gerrit_config {
	include passwords::gerrit

	$gerrit_pass = $passwords::gerrit::gerrit_pass
	$gerrit_db_pass = $passwords::gerrit::gerrit_db_pass
	$gerrit_email_key = $passwords::gerrit::gerrit_email_key

}

class gerrit::crons {

	cron { list_mediawiki_extensions:
		# Gerrit is missing a public list of projects.
		# This hack list MediaWiki extensions repositories
		command => "/bin/ls -1d /var/lib/gerrit2/review_site/git/mediawiki/extensions/*.git | sed 's#.*/##' | sed 's/\\.git//' > /var/www/mediawiki-extensions.txt",
		user => root,
		minute => [0, 15, 30, 45]
	}

	cron { clear_gerrit_logs:
		# Gerrit rotates their own logs, but doesn't clean them out
		# Delete logs older than a week
		command => "find /var/lib/gerrit2/review_site/logs/*.gz -mtime +7 -exec rm {} \\;",
		user => root,
		hour => 1
	}

}
