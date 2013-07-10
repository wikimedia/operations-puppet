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
#      jmx_port                => 9951,
#      ganglia                 => '239.192.1.32:8649,
#      produce_events_warning  => 1000000
#      produce_events_critical => 2000000,
#   }
#
define misc::analytics::monitoring::kafka::producer(
    $jmx_port,
    $ganglia,
    $produce_events_warning,
    $produce_events_critical
)
{
    # Set up a jmxtrans instance sending stats from the Kafka JVM to ganglia.
    jmxtrans::metrics { "kafka-producer-${title}":
        jmx                => "${::fqdn}:${jmx_port}",
        ganglia            => $ganglia,
        ganglia_group_name => 'kafka',
        objects            => [
            {
                'name'        => 'kafka:type=kafka.KafkaProducerStats',
                'resultAlias' => "udp2log_kafka_producer_${title}",
                'attrs'       => {
                    'AvgProduceRequestsMs'       => { 'units' => 'ms', 'dmax'  => $dmax },
                    'MaxProduceRequestsMs'       => { 'units' => 'ms', 'dmax'  => $dmax },
                    'NumProduceRequests'         => { 'units' => 'requests', 'slope' => 'positive', 'dmax'  => $dmax },
                },
            },
            {
                'name'        => 'kafka.producer.Producer:type=AsyncProducerStats',
                'resultAlias' => "udp2log_kafka_producer_${title}",
                'attrs'       => {
                    'AsyncProducerEvents'        => { 'units' => 'events', 'slope' => 'positive', 'dmax'  => $dmax },
                    'AsyncProducerDroppedEvents' => { 'units' => 'events', 'slope' => 'positive', 'dmax'  => $dmax },
                },
            },
        ],
    }


	# Set up icinga monitoring of Kafka producer async produce events per second.
	# If this drops too low, trigger an alert.
	monitor_service { "kafka-producer-${title}.AsyncProducerEvents":
		description           => "kafka_producer_${title}.AsyncProducerEvents",
		check_command         => "check_kafka_producer_produce_events!${title}!${warning}!${critical}",
		contact_group         => "analytics",
	}

	# install a nrpe check for the Kafka producer process for this topic
	nrpe::monitor_service { "kafka_producer_process_${title}":
		description   => "Kafka Producer Process ${title} running",
		nrpe_command  => "/usr/lib/nagios/plugins/check_procs --ereg-argument-array '^java.+kafka.tools.ProducerShell.+--topic=${title}' -c 1:1",
		contact_group => 'analytics',
		retries       => 10,
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
