class gerrit::database-server {

	include gerrit::gerrit_config

	## mysql server package and service are currently being handled by the openstack server
	#package { "mysql-server":
	#	ensure => latest;
	#}
	#
	#service { "mysql":
	#	enable => true,
	#	ensure => running;
	#}

	exec {
		'create_gerrit_db_user':
			unless => "/usr/bin/mysql --defaults-file=/etc/gerrit2/gerrit-user.cnf -e 'exit'",
			command => "/usr/bin/mysql -uroot < /etc/gerrit2/gerrit-user.sql",
			require => [Package["mysql-client"],File["/etc/gerrit2/gerrit-user.sql", "/etc/gerrit2/gerrit-user.cnf", "/root/.my.cnf"]];
		'create_gerrit_db':
			unless => "/usr/bin/mysql -uroot ${gerrit::gerrit_config::gerrit_db_name} -e 'exit'",
			command => "/usr/bin/mysql -uroot -e \"create database ${gerrit::gerrit_config::gerrit_db_name}; ALTER DATABASE reviewdb charset=latin1;\"",
			require => [Package["mysql-client"], File["/root/.my.cnf"]],
			before => Exec['create_gerrit_db_user'];
	}

	file {
		"/etc/gerrit2":
			ensure => directory,
			owner => root,
			group => root,
			mode => 0640;
		"/etc/gerrit2/gerrit-user.sql": 
			content => template("gerrit/gerrit-user.sql.erb"),
			owner => root, 
			group => root,
			mode => 0640,
			require => File["/etc/gerrit2"];
		"/etc/gerrit2/gerrit-user.cnf": 
			content => template("gerrit/gerrit-user.cnf.erb"),
			owner => root, 
			group => root, 
			mode => 0640,
			require => File["/etc/gerrit2"];
	}

}

class gerrit::jetty {
	system_role { "gerrit::jetty": description => "Wikimedia gerrit (git) server" }

	include gerrit::account,
		gerrit::gerrit_config,
		generic::packages::git-core

	package { [ "openjdk-6-jre", "gitweb", "git-svn" ]:
		ensure => latest; 
	} 

	file {
		"/var/lib/gerrit2/gerrit.war":
			source => "puppet:///files/gerrit/gerrit-2.2.1.war",
			owner => root,
			group => root,
			mode => 0444,
			require => Systemuser["gerrit2"];
		"/etc/init.d/gerrit":
			source => "puppet:///files/gerrit/gerrit.sh",
			owner => root,
			group => root,
			mode => 0755;
		"/etc/default/gerritcodereview":
			source => "puppet:///files/gerrit/gerritcodereview",
			owner => root,
			group => root,
			mode => 0444;
		"/var/lib/gerrit2/review_site":
			ensure => directory,
			owner => gerrit2,
			group => gerrit2,
			mode => 0755,
			require => Systemuser["gerrit2"];
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
		"/var/lib/gerrit2/review_site/hooks/change-abandoned":
			owner => gerrit2,
			group => gerrit2,
			mode => 0555,
			source => "puppet:///files/gerrit/hooks/change-abandoned",
			require => Exec["install_gerrit_jetty"];
		"/var/lib/gerrit2/review_site/hooks/hookhelper.py":
			owner => gerrit2,
			group => gerrit2,
			mode => 0555,
			source => "puppet:///files/gerrit/hooks/hookhelper.py",
			require => Exec["install_gerrit_jetty"];
		"/var/lib/gerrit2/review_site/hooks/change-merged":
			owner => gerrit2,
			group => gerrit2,
			mode => 0555,
			source => "puppet:///files/gerrit/hooks/change-merged",
			require => Exec["install_gerrit_jetty"];
		"/var/lib/gerrit2/review_site/hooks/change-restored":
			owner => gerrit2,
			group => gerrit2,
			mode => 0555,
			source => "puppet:///files/gerrit/hooks/change-restored",
			require => Exec["install_gerrit_jetty"];
		"/var/lib/gerrit2/review_site/hooks/comment-added":
			owner => gerrit2,
			group => gerrit2,
			mode => 0555,
			source => "puppet:///files/gerrit/hooks/comment-added",
			require => Exec["install_gerrit_jetty"];
		"/var/lib/gerrit2/review_site/hooks/patchset-created":
			owner => gerrit2,
			group => gerrit2,
			mode => 0555,
			source => "puppet:///files/gerrit/hooks/patchset-created",
			require => Exec["install_gerrit_jetty"];
	}

	exec {
		"install_gerrit_jetty":
			creates => "/var/lib/gerrit2/review_site/bin",
			user => "gerrit2",
			group => "gerrit2",
			cwd => "/var/lib/gerrit2",
			command => "/usr/bin/java -jar gerrit.war init -d review_site --batch --no-auto-start",
			require => [File["/var/lib/gerrit2/gerrit.war", "/var/lib/gerrit2/review_site/etc/gerrit.config"], Package["openjdk-6-jre"], Systemuser["gerrit2"]];
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

class gerrit::proxy {

	include webserver::apache

	file {
		"/etc/apache2/sites-available/gerrit.wikimedia.org":
			mode => 644,
			owner => root,
			group => root,
			source => "puppet:///files/apache/sites/gerrit.wikimedia.org",
			ensure => present;
		# Overwrite gitweb's stupid default apache file
		"/etc/apache2/conf.d/gitweb":
			mode => 644,
			owner => root,
			group => root,
			content => "Alias /gitweb /usr/share/gitweb",
			ensure => present;
	}

	apache_site { gerrit: name => "gerrit.wikimedia.org" }
	apache_module { rewrite: name => "rewrite" }
	apache_module { proxy: name => "proxy" }
	apache_module { proxy_http: name => "proxy_http" }
	apache_module { ssl: name => "ssl" }
}

class gerrit::ircbot {

	include gerrit::gerrit_config

	$ircecho_infile = "/var/lib/gerrit2/review_site/logs/operations.log:#wikimedia-operations,#wikimedia-tech;/var/lib/gerrit2/review_site/logs/labs.log:#wikimedia-labs;/var/lib/gerrit2/review_site/logs/mobile.log:#wikimedia-mobile;/var/lib/gerrit2/review_site/logs/mediawiki.log:#mediawiki"
	$ircecho_nick = "gerrit-wm"
	$ircecho_chans = "#wikimedia-operations,#wikimedia-tech,#wikimedia-labs,#wikimedia-mobile,#mediawiki"
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
			mode => 444,
			owner => root,
			group => root,
			content => template('ircecho/default.erb'),
			notify => Service[ircecho],
			require => Package[ircecho];
	}
}

class gerrit::account { 

	systemuser { gerrit2: name => "gerrit2", home => "/var/lib/gerrit2", shell => "/bin/bash" }

	ssh_authorized_key { gerrit2:
		key => "AAAAB3NzaC1yc2EAAAABIwAAAQEAxOlshfr3UaPr8gQ8UVskxHAGG9xb55xDyfqlK7vsAs/p+OXpRB4KZOxHWqI40FpHhW+rFVA0Ugk7vBK13oKCB435TJlHYTJR62qQNb2DVxi5rtvZ7DPnRRlAvdGpRft9JsoWdgsXNqRkkStbkA5cqotvVHDYAgzBnHxWPM8REokQVqil6S/yHkIGtXO5J7F6I1OvYCnG1d1GLT5nDt+ZeyacLpZAhrBlyFD6pCwDUhg4+H4O3HGwtoh5418U4cvzRgYOQQXsU2WW5nBQHE9LXVLoL6UeMYY4yMtaNw207zN6kXcMFKyTuF5qlF5whC7cmM4elhAO2snwIw4C3EyQgw==",
		type => ssh-rsa,
		user => gerrit2,
		ensure => present;
	}

	file {
		"/var/lib/gerrit2/.ssh/id_rsa":
			owner => gerrit2,
			group => gerrit2,
			mode  => 0600,
			require => [Systemuser["gerrit2"], Ssh_authorized_key["gerrit2"]],
			source => "puppet:///private/gerrit/id_rsa";
	}

}

class gerrit::gerrit_config {

	include openstack::nova_config,
		passwords::gerrit

	$gerrit_hostname = "gerrit.wikimedia.org"
	$gerrit_username = "gerrit2"
	$gerrit_pass = $passwords::gerrit::gerrit_pass
	$gerrit_sshport = "29418"
	$gerrit_url = 'https://gerrit.wikimedia.org/r/'
	$gerrit_db_host = "db9.pmtpa.wmnet"
	$gerrit_db_name = "reviewdb"
	$gerrit_db_user = "gerrit"
	$gerrit_db_pass = $passwords::gerrit::gerrit_db_pass
	$gerrit_ldap_host = $openstack::nova_config::nova_ldap_host
	$gerrit_ldap_base_dn = $openstack::nova_config::nova_ldap_base_dn
	$gerrit_ldap_proxyagent = $openstack::nova_config::nova_ldap_proxyagent
	$gerrit_ldap_proxyagent_pass = $openstack::nova_config::nova_ldap_proxyagent_pass
	$gerrit_listen_url = 'proxy-https://127.0.0.1:8080/r/'
	$gerrit_session_timeout = "90 days"

}
