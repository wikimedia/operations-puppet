# manifests/role/gerrit.pp

class role::gerrit {

	system_role { "role::gerrit": description => "Gerrit installation" }

	class labs {
		system_role { "role::gerrit::production": description => "Gerrit in labs!" }

		gerrit::instance { "gerritlabs":
			self_db => true,
			}
		}


	class production {
		system_role { "role::gerrit::production": description => "Gerrit!" }

		gerrit::instance { "gerritproduction":
			create_account => true,
			ircbot => true,
			apache_ssl => true,
		}
	}

	class production::slave {
		system_role { "role::gerrit::slave": description => "Gerrit slave!" }

		gerrit::instance{ "gerritproductionslave":
			slave => true,
			no_apache => true,
		}
	}

}
