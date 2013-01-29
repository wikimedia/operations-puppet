# == Class kafka::config
#
class kafka::config(
	$zookeeper_hosts                = undef,
	$zookeeper_connectiontimeout_ms = 1000000,
	$kafka_log_file                 = "/var/log/kafka/kafka.log",
	$producer_type                  = "async",
	$producer_batch_size            = 200)
{
	file { "/etc/kafka/log4j.properties":
		content => template("kafka/log4j.properties.erb"),
	}

	file { "/etc/kafka/producer.properties":
		content => template("kafka/producer.properties.erb"),
	}

	file { "/etc/kafka/consumer.properties":
		content => template("kafka/consumer.properties.erb"),
	}
}