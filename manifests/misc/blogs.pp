# https://techblog.wikimedia.org
class misc::techblog {

	system_role { "misc::techblog": description => "Technology blog server" }

	class {'generic::webserver::php5': ssl => 'true'; }

	apache_site { contacts: name => "techblog.wikimedia.org" }
	apache_site { contacts-ssl: name => "techblog.wikimedia.org-ssl" }

}
