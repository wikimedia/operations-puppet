# PHP wmerrors

class php::wmerrors {
	require php

	package { "php5-wmerrors":
		ensure => latest;
	}
}
