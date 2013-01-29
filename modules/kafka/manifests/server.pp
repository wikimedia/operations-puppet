# == Class kafka::server
#
class kafka::server(
	$broker_id                               = undef,
	$log_dir                                 = "/var/lib/kafka/log",
	$port                                    = 9092,
	$num_threads                             = undef,
	$num_partitions                          = 1,
	$socket_send_buffer                      = 1048576,
	$socket_receive_buffer                   = 1048576,
	$max_socket_request_bytes                = 104857600,
	$log_flush_interval                      = 10000,
	$log_default_flush_interval_ms           = 1000, 
	$log_default_flush_scheduler_interval_ms = 1000,
	$log_retention_hours                     = 168, # 1 week
	$log_retention_size                      = -1,
	$log_file_size                           = 536870912,
	$log_cleanup_interval_mins               = 1)
{
	# Infer the $brokerid from numbers in the hostname
	# if is not manually passed in as $broker_d
	$brokerid = $broker_id ? {
		undef   => inline_template('<%= hostname.gsub(/[^\d]/, "").to_i %>'),
		default => $broker_id
	}

	# define local variables from kafka::config class for use in ERb template.
	$zookeeper_hosts                = $kafka::config::zookeeper_hosts
	$zookeeper_connectiontimeout_ms = $kafka::config::zookeeper_connectiontimeout_ms

	file { "/etc/kafka/server.properties":
		content => template("kafka/server.properties.erb"),
		require => [Class["kafka::config"], Class["kafka::install"]],
	}

	file { $log_dir:
		owner   => "kafka",
		group   => "kafka",
		mode    => 0755,
		ensure  => "directory",
		require => Class["kafka::install"],
	}

	service { "kafka":
		ensure     => running,
		require    => [Class["kafka::install"], File["/etc/kafka/server.properties"], File[$log_dir]],
		hasrestart => true,
		hasstatus  => true,
	}
}
