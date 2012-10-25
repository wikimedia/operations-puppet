# PHP ldap

class php::ldap {
	require php

	package { "php5-ldap":
		ensure => latest;
	}
}
