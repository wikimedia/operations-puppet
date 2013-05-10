#  This is production RT
#
class role::request-tracker::production {

	class { "misc::rt::server":
		site => "rt.wikimedia.org";
	}
}

#  Labs/testing RT
#
class role::request-tracker::labs {

	class { "misc::rt::server":
		site => $fqdn,
		datadir => "/a/mysql";
	}
}

#  Labs/testing RT with Apache
#
class role::request-tracker-apache::labs {
	include passwords::misc::rt

	class { "misc::rt-apache::server":
		dbuser => passwords::misc::rt::rt_mysql_user,
		dbpass => passwords::misc::rt::rt_mysql_pass,
		site => $fqdn,
		datadir => "/a/mysql",
	}

	class { 'generic::mysql::server':
		version => $::lsbdistrelease ? {
			'12.04' => '5.5',
			default => false,
		},
		datadir => $datadir;
	}
}

#  Production RT with Apache
#
class role::request-tracker-apache::production {
	include passwords::misc::rt

	class { "misc::rt-apache::server":
		site => 'rt.wikimedia.org',
		dbhost => 'db1001',
		dbport => '',
		dbuser => passwords::misc::rt::rt_mysql_user,
		dbpass => passwords::misc::rt::rt_mysql_pass,
	}
}
