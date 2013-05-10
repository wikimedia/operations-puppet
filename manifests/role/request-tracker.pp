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

	class { "misc::rt-apache::server":
		site => $fqdn,
		datadir => "/a/mysql";
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
class role::request-tracker-apache::labs {

	class { "misc::rt-apache::server":
		site => "rt.wikimedia.org";
	}
}

