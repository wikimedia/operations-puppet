# role/redis.pp
# db::redis

# Virtual resource for the monitoring server
@monitor_group { "redis_eqiad": description => "eqiad Redis" }
@monitor_group { "redis_pmtpa": description => "pmtpa Redis" }

class role::db::redis (
	$maxmemory = inline_template("<%= (Float(memorysize.split[0]) * 0.82).round %>Gb"),
	$redis_replication = undef,
) {
	$cluster = "redis"

	system_role { "db::redis": description => "Redis server" }

	include standard,
		passwords::redis

	class { "::redis":
		maxmemory => $maxmemory,
		persist => "aof",
		redis_replication => $redis_replication,
		password => $passwords::redis::main_password,
	}

	include redis::ganglia

}

