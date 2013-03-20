class role::db::redis::labs {
	class { "redis":
		$dir => "/var/lib/redis/"
	}
}
