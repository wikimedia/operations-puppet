# PHP redis

class php::redis {
	require php

	package { "php5-redis":
		ensure => latest;
	}
}
