# The following class is obsolete, please use the mysql module instead.

# installs mysql-server, configures app armor
# and my.cnf, starts mysqld.
#
# Most of these defaults are from the
# debian install + the default .deb my.cnf
class generic::mysql::server(
	$version                        = "5.1",
	$datadir                        = "/var/lib/mysql",
	$port                           = 3306,
	$bind_address                   = "127.0.0.1",
	$socket                         = false,
	$pid_file                       = false,

	# logging
	$log_error                      = "/var/log/mysql/mysql.err",
	$slow_query_log_file            = false,
	$long_query_time                = 10,

	$basedir                        = "/usr",
	$tmpdir                         = "/tmp",

	# Buffers, Threads, Caches, Limits
	$tmp_table_size                 = '16M',
	$max_heap_table_size            = '16M',
	$max_tmp_tables                 = '32',

	$join_buffer_size               = '3M',
	$read_buffer_size               = '4M',
	$sort_buffer_size               = '4M',

	$table_cache                    = '64',
	$table_definition_cache         = '256',
	$open_files_limit               = '1024',

	$thread_stack                   = '192K',
	$thread_cache_size              = '8',
	$thread_concurrency             = '10',

	$query_cache_size               = '16M',
	$query_cache_limit              = '1M',
	$tmp_table_size                 = '16M',
	$read_rnd_buffer_size           = '256K',

	$key_buffer_size                = '16M',
	$myisam_sort_buffer_size        = '8M',
	$myisam_max_sort_file_size      = '512M',

	# Networking
	$max_allowed_packet             = "16M",
	$max_connections                = '151',
	$wait_timeout                   = "28800",
	$connect_timeout                = "10",

	# InnoDB settings.
	$innodb_file_per_table          = '1',
	$innodb_status_file             = '0',
	$innodb_support_xa              = '0',
	$innodb_flush_log_at_trx_commit = '0',
	$innodb_buffer_pool_size        = '8M',
	$innodb_log_file_size           = '5M',
	$innodb_flush_method            = 'O_DIRECT',
	$innodb_thread_concurrency      = '8',
	$innodb_concurrency_tickets     = '500',
	$innodb_doublewrite             = '1',

	# set read_only to true if you want this instance to be read_only
	$read_only                      = false,

	# set replication_enabled to false if you don't want to enable binary logging
	$replication_enabled            = false,
	# These settings won't matter if replication_enabled is false.

	$expire_logs_days               = '10',
	$replicate_ignore_table         = [],
	$replicate_ignore_db            = [],
	$replicate_do_table             = [],
	$replicate_do_db                = [],

	$extra_configs                  = {},
	$config_file_path               = "/etc/mysql/my.cnf"
	)
{
	# make sure mysql-server and mysql-client are
	# installed with the specified version.
	include mysql::server::package, mysql
	include generic::apparmor::service

        # /var/run has moved to /run in newer Ubuntu versions.
        # See: http://lwn.net/Articles/436012/
        if $::lsbdistid == 'Ubuntu' and versioncmp($::lsbdistrelease, '11.10') >= 0 {
            $run_directory = '/run'
        } else {
            $run_directory = '/var/run'
        }

	# if $socket was not manually specified,
	# assume that the socket file should live in
	# $run_directory/mysqld/mysqld.sock, otherwise
	# just use the path that was given.
	$socket_path = $socket ? {
		false   => "$run_directory/mysqld/mysqld.sock",
		default => $socket,
	}
	# if $pid_file was not manually specified,
	# assume that the pid file should live in
	# $run_directory/mysqld/mysqld.sock, otherwise
	# just use the path that was given.
	$pid_path = $pid_file ? {
		false   => "$run_directory/mysqld/mysqld.pid",
		default => $pid_file,
	}

	# This is needed because reconfigure creates $datadir and the necessary files inside.
	#  The sleep is to avoid mysql getting canned for speedy respawn;
	#   the retry is to give apparmor a chance to settle in.
	exec { "dpkg-reconfigure mysql-server":
		command => "/bin/sleep 30; /usr/sbin/dpkg-reconfigure -fnoninteractive mysql-server-${version}",
		require => [File["/etc/apparmor.d/usr.sbin.mysqld"]],
		tries => 2,
		refreshonly => true,
	}

	# Put my.cnf in place from the generic_my.cnf.erb template.
	# The values in this file are filled in from the
	# passed in parameters.
	file { $config_file_path:
		owner => 'root',
		group => 'root',
		mode  => 0644,
		content => template('mysql/generic_my.cnf.erb'),
		require => [Package["mysql-server"], File["/etc/apparmor.d/usr.sbin.mysqld"]],
		notify => [Exec["dpkg-reconfigure mysql-server"]]
	}

	# mysql is protected by apparmor.  Need to
	# reload apparmor if the file changes.
	file { "/etc/apparmor.d/usr.sbin.mysqld":
		owner => 'root',
		group => 'root',
		mode => 0644,
		content => template('mysql/apparmor.usr.sbin.mysqld.erb'),
		require => Package["mysql-server"],
		notify => Service["apparmor"],
	}

	service { "mysql":
		ensure => "running",
		require => [Package["mysql-server"], File[$config_file_path, "/etc/apparmor.d/usr.sbin.mysqld"]],
		# don't subscribe mysql to its config files.
		# it is better to be able to restart mysql
		# manually when you intend for it to happen,
		# rather than allowing puppet to do it without
		# your supervision.
	}
}

