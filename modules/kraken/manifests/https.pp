# == Class kraken::https
# Sets up an HTTPS proxy with
# HTTP authentication that proxies
# requests that match $proxy_url_regex
# to to the matched URL on port $proxy_port.
#
# This requires the incoming Host header
# resolves to a proxy service somewhere (probably on localhost)
# that knows how to map the Host to the proper location.
# (See class kraken::proxy for an example).
#
class kraken::https(
	$proxy_port       = 81,
	$proxy_url_regex  = '.*kraken\.wikimedia\.org',
	$http_auth        = {},
	$ensure           = present
) {
	include apache,
		apache::mod::auth_basic,
		apache::mod::ssl,
		apache::mod::proxy,
		apache::mod::proxy_http

	# Render /etc/apache2/kraken.htpasswd with contents of $http_auth
	file { "/etc/apache2/kraken.htpasswd":
		content => template("kraken/kraken.htpasswd.erb"),
		owner   => $apache::params::user,
		group   => $apache::params::group,
		mode    => "0600",
		ensure  => $ensure ? {
			present   => "file",
			default   => absent,
		},
	}

	# Install https-proxy vhost and sites-enabled symlink
	file { "/etc/apache2/sites-available/https-proxy":
		content => template("kraken/apache.https-proxy.vhost.erb"),
		require => File["/etc/apache2/kraken.htpasswd"],
		notify  => Service["httpd"],
	}
	file { "/etc/apache2/sites-enabled/001-https-proxy":
		notify     => Service["httpd"],
		# if present, symlink to sites-available file
		ensure     => $ensure ? {
			present   => "/etc/apache2/sites-available/https-proxy",
			default   => "absent",
		},
	}
}