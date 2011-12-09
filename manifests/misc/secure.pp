# (old) SSL secure.wm host
# https://secure.wikimedia.org | http://en.wikipedia.org/wiki/Wikipedia:Secure_server
class misc::secure {
	system_role { "misc::secure": description => "secure.wikimedia.org" }

	class {'generic::webserver::php5': ssl => 'true'; }

	apache_module { rewrite: name => "rewrite" }
	apache_module { proxy: name => "proxy" }
	apache_module { proxy_http: name => "proxy_http" }

	apache_site { secure: name => "secure.wikimedia.org" }
}
