# PHP mysql

class php::mysql {
	require php

	package { "php5-mysql":
		ensure => latest;
	}
}
