# manifests/role/gerrit.pp

class role::gerrit {

	system_role { "role::gerrit": description => "Gerrit installation" }

	# role::gerrit::base include some common packages
	class base {
		include standard,
			ldap::client::wmf-cluster,
			role::gerrit::apache,
			role::gerrit::jetty,
			role::gerrit::gitweb,
			gerrit::crons
	}

	class labs inherits role::gerrit::base {
		# Production does this via db9. Labs needs a database
		package { ["mysql-server", "mysql-client"]:
			ensure => latest;
		}

		service { "mysql":
			enable => true,
			ensure => running;
		}

		exec {
			'create_gerrit_db_user':
				unless => "/usr/bin/mysql --defaults-file=/etc/gerrit2/gerrit-user.cnf -e 'exit'",
				command => "/usr/bin/mysql -uroot < /etc/gerrit2/gerrit-user.sql",
				require => [Package["mysql-client"],File["/etc/gerrit2/gerrit-user.sql", "/etc/gerrit2/gerrit-user.cnf", "/root/.my.cnf"]];
			'create_gerrit_db':
				unless => "/usr/bin/mysql -uroot ${gerrit::gerrit_config::gerrit_db_name} -e 'exit'",
				command => "/usr/bin/mysql -uroot -e \"create database ${gerrit::gerrit_config::gerrit_db_name}; ALTER DATABASE reviewdb charset=latin1;\"",
				require => Package["mysql-client"],
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


	class production inherits role::gerrit::base {
		include role::gerrit::ircbot,
			role::gerrit::account
	}

	class account {
		ssh_authorized_key { gerrit2:
			key => "AAAAB3NzaC1yc2EAAAABIwAAAQEAxOlshfr3UaPr8gQ8UVskxHAGG9xb55xDyfqlK7vsAs/p+OXpRB4KZOxHWqI40FpHhW+rFVA0Ugk7vBK13oKCB435TJlHYTJR62qQNb2DVxi5rtvZ7DPnRRlAvdGpRft9JsoWdgsXNqRkkStbkA5cqotvVHDYAgzBnHxWPM8REokQVqil6S/yHkIGtXO5J7F6I1OvYCnG1d1GLT5nDt+ZeyacLpZAhrBlyFD6pCwDUhg4+H4O3HGwtoh5418U4cvzRgYOQQXsU2WW5nBQHE9LXVLoL6UeMYY4yMtaNw207zN6kXcMFKyTuF5qlF5whC7cmM4elhAO2snwIw4C3EyQgw==",
			type => ssh-rsa,
			user => gerrit2,
			require => Package["gerrit"],
			ensure => present;
		}

		file {
			"/var/lib/gerrit2/.ssh/id_rsa":
				owner => gerrit2,
				group => gerrit2,
				mode  => 0600,
				require => [Package["gerrit"], Ssh_authorized_key["gerrit2"]],
				source => "puppet:///private/gerrit/id_rsa";
		}
	}

	class apache {

		if !$gerrit_no_apache {
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
		if $realm == 'production' {
			apache_module { ssl: name => "ssl" }
		}
	}

}
