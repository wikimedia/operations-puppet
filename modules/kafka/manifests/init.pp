# == Class kafka
#
class kafka(
	$zookeeper_hosts                = undef,
	$zookeeper_connectiontimeout_ms = 1000000,
	$kafka_log_file                 = "/var/log/kafka/kafka.log",
	$producer_type                  = "async",
	$producer_batch_size            = 200)
{
	package { "kafka": ensure => "installed" }

	file { "/etc/kafka/log4j.properties":
		content => template("kafka/log4j.properties.erb"),
		require => Package["kafka"],
	}

	file { "/etc/kafka/producer.properties":
		content => template("kafka/producer.properties.erb"),
		require => Package["kafka"],
	}

	file { "/etc/kafka/consumer.properties":
		content => template("kafka/consumer.properties.erb"),
		require => Package["kafka"],
	}
}
