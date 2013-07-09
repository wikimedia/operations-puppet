# Temporary puppetization of interim needs while
# Analytics and ops works together to review and puppetize
# Kraken in the production branch of operations/puppet.
# This file will be deleted soon.


# Syncs an HDFS directory to $rsync_destination via rsync hourly
define misc::analytics::hdfs::sync($hdfs_source, $rsync_destination, $tmp_dir = "/a/hdfs_sync.tmp") {
	require misc::statistics::user

	file { $tmp_dir:
		ensure => directory,
		owner  => $misc::statistics::user::username,
	}

	$local_tmp_dir = "${tmp_dir}/${name}"
	$command       = "/bin/rm -rf ${local_tmp_dir} && /usr/bin/hadoop fs -get ${hdfs_source} ${local_tmp_dir} && /usr/bin/rsync -rt --delete ${local_tmp_dir}/ ${rsync_destination} && /bin/rm -rf ${local_tmp_dir}"

	# Create an hourly cron job to rsync to $rsync_destination.
	cron { "hdfs_sync_${name}":
		command => $command,
		user    => $misc::statistics::user::username,
		minute  => 15,
		require => File[$tmp_dir],
	}
}

# == Define misc::analytics::monitoring::kafka::producer
# Sets up Icinga alerts for a Kafka Producer identified by $topic.
#
# == Parameters:
# $warning
# $critical
#
# Usage:
#   misc::analytics::monitoring::kafka::producer { 'webrequest-mobile':
#      warning  => 1,
#      critical => 5,
#   }
#
define misc::analytics::monitoring::kafka::producer($warning, $critical) {
	# Set up icinga monitoring of Kafka producer async produce events per second.
	# If this drops too low, trigger an alert.
	monitor_service { "kafka-producer-${title}.AsyncProducerEvents":
		description           => "kafka_producer_${title}.AsyncProducerEvents",
		check_command         => "check_kafka_producer_produce_events!${title}!${warning}!${critical}",
		contact_group         => "analytics",
	}
}


class misc::analytics::monitoring::kafka::server {
	# Set up icinga monitoring of Kafka broker server produce requests per second.
	# If this drops too low, trigger an alert
	monitor_service { "kakfa-broker-ProduceRequestsPerSecond_min":
		description           => "kafka_network_SocketServerStats.ProduceRequestsPerSecond_min",
		check_command         => "check_kafka_broker_produce_requests_min!5!1",
		contact_group         => "analytics",
	}

	# Set up icinga monitoring of Kafka broker server produce requests per second.
	# If this drops too low, trigger an alert
	monitor_service { "kakfa-broker-ProduceRequestsPerSecond_max":
		description           => "kafka_network_SocketServerStats.ProduceRequestsPerSecond_max",
		check_command         => "check_kafka_broker_produce_requests_max!15!20",
		contact_group         => "analytics",
	}
}
