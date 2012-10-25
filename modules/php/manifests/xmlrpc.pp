# PHP xmlrpc

class php::xmlrpc {
	require php

	package { "php5-xmlrpc":
		ensure => latest;
	}
}
