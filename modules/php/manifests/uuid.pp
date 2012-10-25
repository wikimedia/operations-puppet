# PHP uuid

class php::uuid {
	require php

	package { "php5-uuid":
		ensure => latest;
	}
}
