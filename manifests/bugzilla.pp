class bugzilla::server {
  include bugzilla::config
}

class bugzilla::config {

	include openstack::nova_config

	$hostname = "bugzilla.wikimedia.org"
	# $gerrit_username = "gerrit2"
	# $gerrit_pass = $passwords::gerrit::gerrit_pass
	# $gerrit_sshport = "29418"
	$url = 'https://bugzilla.wikimedia.org/'
	$db_host = ""
	$db_name = ""
	$db_charset = "utf8"
	$db_user = ""
	$db_pass = $passwords::bugzilla::bugzilla_db_pass
	# $gerrit_ldap_host = $openstack::nova_config::nova_ldap_host
	# $gerrit_ldap_base_dn = $openstack::nova_config::nova_ldap_base_dn
	# $gerrit_ldap_proxyagent = $openstack::nova_config::nova_ldap_proxyagent
	# $gerrit_ldap_proxyagent_pass = $openstack::nova_config::nova_ldap_proxyagent_pass
	# $gerrit_listen_url = 'proxy-https://127.0.0.1:8080/r/'
	$session_timeout = "90 days"

}

class bugzilla::crons {

	# cron { list_mediawiki_extensions:
	# 	# Gerrit is missing a public list of projects.
	# 	# This hack list MediaWiki extensions repositories
	# 	command => "/bin/ls -1d /var/lib/gerrit2/review_site/git/mediawiki/extensions/*.git | sed 's#.*/##' | sed 's/\\.git//' > /var/www/mediawiki-extensions.txt",
	# 	user => root,
	# 	minute => [0, 15, 30, 45]
	# }

}

class bugzilla::database-server {

	include bugzilla::config

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
		'create_bugzilla_db_user':
			unless => "/usr/bin/mysql --defaults-file=/etc/gerrit2/gerrit-user.cnf -e 'exit'",
			command => "/usr/bin/mysql -uroot < /etc/gerrit2/gerrit-user.sql",
			require => [Package["mysql-client"],File["/etc/gerrit2/gerrit-user.sql",
                                                                 "/etc/gerrit2/gerrit-user.cnf", "/root/.my.cnf"]];
		'create_bugzilla_db':
			unless => "/usr/bin/mysql -uroot ${bugzilla::config::db_name} -e 'exit'",
			command => "/usr/bin/mysql -uroot -e \"create database ${bugzilla::config::db_name}; \
					ALTER DATABASE ${bugzilla::config::db_name} charset=${bugzilla::config::db_charset};\"",
			require => [Package["mysql-client"], File["/root/.my.cnf"]],
			before => Exec['create_bugzilla_db_user'];
	}

	file {
		"/etc/bugzilla4":
			ensure => directory,
			owner => root,
			group => www-data,
			mode => 0775;
	}

}
