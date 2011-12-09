# (old) SSL secure.wm host
# https://secure.wikimedia.org | http://en.wikipedia.org/wiki/Wikipedia:Secure_server
class misc::securewm {
	system_role { "misc::securewm": description => "secure.wm server" }

	class {'generic::webserver::php5': ssl => 'true'; }

	apache_module { rewrite: name => "rewrite" }
	apache_module { proxy: name => "proxy" }
	apache_module { proxy_http: name => "proxy_http" }

	apache_site { contacts: name => "secure.wikimedia.org" }
}
