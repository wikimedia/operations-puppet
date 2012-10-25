# PHP cgi

class php::cgi {
	require php

	package { "php5-cgi":
		ensure => latest;
	}
}
