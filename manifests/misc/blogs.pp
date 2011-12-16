# Wikimedia Blogs

# https://blog.wikimedia.org/
class misc::blog-wikimedia {
	system_role { "misc::blog-wikimedia": description => "blog.wikimedia.org" }

	require apaches::packages,
		generic::php5-gd

	file {
		"/etc/apache2/sites-available/blog.wikimedia.org":
			path => "/etc/apache2/sites-available/blog.wikimedia.org",
			mode => 0444,
			owner => root,
			group => root,
			source => "puppet:///files/apache/sites/blog.wikimedia.org";
	}
}

# https://techblog.wikimedia.org
class misc::techblog {

	system_role { "misc::techblog": description => "Technology blog server" }

	class {'generic::webserver::php5': ssl => 'true'; }

	apache_site { contacts: name => "techblog.wikimedia.org" }
	apache_site { contacts-ssl: name => "techblog.wikimedia.org-ssl" }

}
