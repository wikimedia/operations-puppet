# analytics.pp

# Contains classes and definitions for configuring
# the Kraken Analytics cluster nodes.
#
# NOTE:  This may be moved to an analytics module.


# == Class analytics::web::proxy
#
# == Parameters
# $port    port on which to listen.
# Sets up an htpasswd auth protected HTTP proxy.
# This allows access to Hadoop HTTP interfaces
# on machines without public IPs.
class analytics::web::proxy {
	include webserver::apache
	webserver::apache::module { "rewrite": require => Class["webserver::apache"] }
	webserver::apache::module { "proxy":   require => Class["webserver::apache"] }

	# htpasswd file for wmf-analytics
	file { "/srv/.htpasswd":
		content => 'wmf-analytics:$apr1$SqaQGuwl$JYKiX78Q2wqEUowYreaFw1',
		mode    => 0644,
		owner   => root,
		group   => root,
	}

	# not using webserver::apache::site here, since I
	# need to specify a custom port on which to listen.
	file { "/etc/apache2/sites-available/proxy":
		notify  => Service["apache2"],
		require => [File["/srv/.htpasswd"], Webserver::Apache::Module["rewrite"], Webserver::Apache::Module["proxy"]],
		content => "
Listen 8085
<VirtualHost *:8085>
	ErrorLog /var/log/apache2/error.log
	# Possible values include: debug, info, notice, warn, error, crit,
	# alert, emerg.
	LogLevel warn

	CustomLog /var/log/apache2/access.log combined
	ServerSignature On

	ProxyRequests Off
	<Proxy *>
		Order allow,deny
		Allow from all
	</Proxy>

	UseCanonicalName Off
	UseCanonicalPhysicalPort Off

	RewriteEngine On
	RewriteLog /var/log/apache2/rewrite.log
	RewriteLogLevel 9
	RewriteRule \"^(.*)\" \"http://%{HTTP_HOST}\$1\" [P]

	<Location />
		Order deny,allow
		AuthType Basic
		AuthName \"wmf-analytics\"
		AuthUserFile /srv/.htpasswd
		require valid-user
	</Location>
</VirtualHost>
"
	}

	# symlink sites-enabled to sites-available file.
	file { "/etc/apache2/sites-enabled/proxy":
		ensure => "/etc/apache2/sites-available/proxy",
		notify => Service["apache2"],
	}
}


# == Class analytics::db::mysql
# 
class analytics::db::mysql {
	# install a mysql server with the
	# datadir at /a/mysql
	class { "generic::mysql::server":
		datadir => "/a/mysql",
		version => "5.5",
	}
}
