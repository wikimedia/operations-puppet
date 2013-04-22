# class for sending sending slow query digest logs
class coredb_mysql::slow_digest {
	include passwords::mysql::querydigest
	$mysql_user = "ops"
	$digest_host = "db1001.eqiad.wmnet"
	$digest_db = "query_digests"

	file {
		"/usr/local/bin/send_query_digest.sh":
			owner => root,
			group => root,
			mode => 0500,
			content => template("coredb_mysql/send_query_digest.sh.erb");
	}

	cron {
		slow_digest:
			command => "/usr/local/bin/send_query_digest.sh >/dev/null 2>&1",
			require => File["/usr/local/bin/send_query_digest.sh"],
			user => root,
			minute => '*/20',
			hour => '*',
			ensure => present;
		tcp_query_digest:
			command => "/usr/local/bin/send_query_digest.sh tcpdump >/dev/null 2>&1",
			require => File["/usr/local/bin/send_query_digest.sh"],
			user => root,
			minute => [5, 25, 45],
			hour => '*',
			ensure => present;
	}
}
