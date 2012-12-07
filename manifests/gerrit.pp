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
		$db_user="gerrit",
		$ssh_key="",
		$ssl_cert="ssl-cert-snakeoil",
		$ssl_cert_key="ssl-cert-snakeoil",
		$ssl_ca="wmf-ca",
		$replication="",
		$smtp_host="") {

	include standard,
		role::ldap::config::labs,
		generic::packages::git-core

	# Main config
	include passwords::gerrit
	$email_key = $passwords::gerrit::gerrit_email_key
	$sshport = $ssh_port
	$dbhost = $db_host
	$dbname = $db_name
	$dbuser = $db_user
	$dbpass = $passwords::gerrit::gerrit_db_pass

	# Setup LDAP
	include role::ldap::config::labs
	$ldapconfig = $role::ldap::config::labs::ldapconfig

	$ldap_hosts = $ldapconfig["servernames"]
	$ldap_base_dn = $ldapconfig["basedn"]
	$ldap_proxyagent = $ldapconfig["proxyagent"]
	$ldap_proxyagent_pass = $ldapconfig["proxypass"]

	# Configure the base URL
	$url = "https://${host}/r"

	class {'gerrit::proxy':
		no_apache => $no_apache,
		ssl_cert => $ssl_cert,
		ssl_cert_key => $ssl_cert_key,
		ssl_ca => $ssl_ca,
		host => $host
	}

	class {'gerrit::jetty':
		ldap_hosts => $ldap_hosts,
		ldap_base_dn => $ldap_base_dn,
		url => $url,
		dbhost => $dbhost,
		dbname => $dbname,
		dbuser => $dbuser,
		hostname => $host,
		ldap_proxyagent => $ldap_proxyagent,
		ldap_proxyagent_pass => $ldap_proxyagent_pass,
		sshport => $sshport,
		replication => $replication,
		smtp_host => $smtp_host,
		ssh_key => $ssh_key,
	}

	# Optional modules
	if $ircbot { include gerrit::ircbot }
}

class gerrit::jetty ($ldap_hosts,
		$ldap_base_dn,
		$url,
		$dbhost,
		$dbname,
		$dbuser,
		$hostname,
		$sshport,
		$ldap_proxyagent,
		$ldap_proxyagent_pass,
		$replication,
		$smtp_host,
		$ssh_key) {

	include gerrit::crons,
		gerrit::gitweb

	package { [ "openjdk-6-jre", "git-svn" ]:
		ensure => latest;
	}

	package { [ "python-paramiko" ]:
		ensure => latest;
	}

	package { [ "gerrit" ]:
		ensure => present;
	}

	# TODO: Make this go away -- need to stop using gerrit2 for hook actions
	ssh_authorized_key { $name:
		key => $ssh_key,
		type => "ssh-rsa",
		user => "gerrit2",
		require => Package["gerrit"],
		ensure => present;
	}

	file {
		"/etc/default/gerrit":
			source => "puppet:///files/gerrit/gerrit",
			owner => root,
			group => root,
			mode => 0444;
		"/var/lib/gerrit2/":
			mode  => 0755,
			owner => "gerrit2",
			ensure => directory,
			require => Package["gerrit"];
		"/var/lib/gerrit2/.ssh":
			mode  => 0600,
			owner => "gerrit2",
			ensure => directory,
			require => File["/var/lib/gerrit2"];
		"/var/lib/gerrit2/.ssh/id_rsa":
			owner => gerrit2,
			group => gerrit2,
			mode  => 0600,
			require => File["/var/lib/gerrit2/.ssh"],
			source => "puppet:///private/gerrit/id_rsa";
		"/var/lib/gerrit2/review_site":
			ensure => directory,
			owner => gerrit2,
			group => gerrit2,
			mode => 0755,
			require => [File["/var/lib/gerrit2"],
				Package["gerrit"]];
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
		"/var/lib/gerrit2/review_site/etc/replication.config":
			content => template('gerrit/replication.config.erb'),
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
			require => [Package["gerrit"], File["/var/lib/gerrit2/review_site/etc/gerrit.config"],
			  File["/var/lib/gerrit2/review_site/etc/secure.config"]
			];
	}

	service {
		"gerrit":
			subscribe => [File["/var/lib/gerrit2/review_site/etc/gerrit.config"],
				File["/var/lib/gerrit2/review_site/etc/secure.config"],
				File["/var/lib/gerrit2/review_site/etc/replication.config"]],
			enable => true,
			ensure => running,
			hasstatus => false,
			status => "/etc/init.d/gerrit check",
			require => Exec["install_gerrit_jetty"];
	}

}

class gerrit::proxy( $no_apache = true,
		$host = "",
		$ssl_cert="",
		$ssl_cert_key="",
		$ssl_ca="") {

	if !$no_apache {
		require webserver::apache
		apache_site { 000_default: name => "000-default", ensure => absent }
	}

	file {
		"/etc/apache2/sites-available/gerrit.wikimedia.org":
			mode => 0644,
			owner => root,
			group => root,
			content => template('apache/sites/gerrit.wikimedia.org.erb'),
			ensure => present;
	}

	apache_site { gerrit: name => "gerrit.wikimedia.org" }
	apache_module { rewrite: name => "rewrite" }
	apache_module { proxy: name => "proxy" }
	apache_module { proxy_http: name => "proxy_http" }
	apache_module { ssl: name => "ssl" }
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

	$ircecho_infile = "/var/lib/gerrit2/review_site/logs/operations.log:#wikimedia-operations;/var/lib/gerrit2/review_site/logs/labs.log:#wikimedia-labs;/var/lib/gerrit2/review_site/logs/mobile.log:#wikimedia-mobile;/var/lib/gerrit2/review_site/logs/parsoid.log:#mediawiki-parsoid;/var/lib/gerrit2/review_site/logs/visualeditor.log:#mediawiki-visualeditor;/var/lib/gerrit2/review_site/logs/mediawiki.log:#mediawiki;/var/lib/gerrit2/review_site/logs/wikimedia-dev.log:#wikimedia-dev;/var/lib/gerrit2/review_site/logs/semantic-mediawiki.log:#semantic-mediawiki,#mediawiki;/var/lib/gerrit2/review_site/logs/wikidata.log:#wikimedia-wikidata"
	$ircecho_nick = "gerrit-wm"
	$ircecho_chans = "#wikimedia-operations,#wikimedia-labs,#wikimedia-mobile,#mediawiki-parsoid,#mediawiki-visualeditor,#mediawiki,#wikimedia-dev,#wikimedia-wikidata,#semantic-mediawiki"
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

# Setup the `gerritslave` account on any host that wants to receive
# replication. See role::gerrit::production::replicationdest
class gerrit::replicationdest( $sshkey, $extra_groups = undef, $slaveuser = "gerritslave" ) {
  systemuser { $slaveuser:
    name => $slaveuser,
    groups => $extra_groups,
    shell => "/bin/bash";
  }

  ssh_authorized_key { $slaveuser:
    key => $sshkey,
    type => "ssh-rsa",
    user => $slaveuser,
    require => Systemuser[$slaveuser],
    ensure => present;
  }

  # Make sure we've got git.
  include generic::packages::git-core
}
