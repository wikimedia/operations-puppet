# (old) SSL secure.wm host
# https://secure.wikimedia.org | http://en.wikipedia.org/wiki/Wikipedia:Secure_server
class misc::secure {
	system_role { "misc::secure": description => "secure.wikimedia.org" }
	apache_module { rewrite: name => "rewrite" }

	file {
		"/etc/apache2/sites-available/secure.wikimedia.org":
			source => "puppet:///files/apache/sites/secure.wikimedia.org",
			owner => root,
			group => root,
			mode => 0444;
	}

	apache_site { secure: name => "secure.wikimedia.org" }
}
