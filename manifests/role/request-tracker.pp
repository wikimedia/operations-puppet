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

