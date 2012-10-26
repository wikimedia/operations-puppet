# PHP apache2module

class php::apache2module {
	require php

	package { "libapache2-mod-php5":
		ensure => latest;
	}
}
