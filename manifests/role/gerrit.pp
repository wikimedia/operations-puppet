# manifests/role/gerrit.pp

class role::gerrit {

	system_role { "role::gerrit": description => "Gerrit installation" }

	class labs {
		system_role { "role::gerrit::production": description => "Gerrit in labs!" }

		gerrit::instance { "gerrit-dev.wmflabs.org":
			ircbot => false,
			db_host => "gerrit-db"
		}
	}


	class production {
		system_role { "role::gerrit::production": description => "Gerrit master" }

		gerrit::instance { "gerrit.wikimedia.org":
			ircbot => true,
			apache_ssl => true,
			db_host => "db1048.eqiad.wmnet"
		}
	}

	class production::slave {
		system_role { "role::gerrit::slave": description => "Gerrit slave" }

		gerrit::instance{ "formey.wikimedia.org":
			slave => true,
			no_apache => true,
			db_host => "db1048.eqiad.wmnet"
		}
	}

}
