# manifests/role/gerrit.pp

class role::gerrit {

	system_role { "role::gerrit": description => "Gerrit installation" }

	class labs {
		system_role { "role::gerrit::production": description => "Gerrit in labs!" }

		class { "gerrit::instance":
			ircbot => false,
			db_host => "gerrit-db",
			host => "gerrit-dev.wmflabs.org"
		}
	}


	class production {
		system_role { "role::gerrit::production": description => "Gerrit master" }

		class { "gerrit::instance":
			ircbot => true,
			apache_ssl => true,
			db_host => "db1048.eqiad.wmnet",
			host => "gerrit.wikimedia.org"
		}
	}

	class production::slave {
		system_role { "role::gerrit::slave": description => "Gerrit slave" }

		class { "gerrit::instance":
			slave => true,
			no_apache => true,
			db_host => "db1048.eqiad.wmnet",
			host => "formey.wikimedia.org"
		}
	}

}
