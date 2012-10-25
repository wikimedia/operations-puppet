# PHP sqlite

class php::sqlite {
	require php

	package { "php5-sqlite":
		ensure => latest;
	}
}
