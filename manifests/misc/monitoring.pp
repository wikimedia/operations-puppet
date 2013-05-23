# misc/monitoring.pp

class misc::monitoring::htcp-loss {
	system_role { "misc::monitoring::htcp-loss": description => "HTCP packet loss monitor" }

	File {
		require => File["/usr/lib/ganglia/python_modules"],
		notify => Service[gmond]
	}

	# Ganglia
	file {
		"/usr/lib/ganglia/python_modules/htcpseqcheck.py":
			source => "puppet:///files/ganglia/plugins/htcpseqcheck.py";
		"/usr/lib/ganglia/python_modules/htcpseqcheck_ganglia.py":
			source => "puppet:///files/ganglia/plugins/htcpseqcheck_ganglia.py";
		"/usr/lib/ganglia/python_modules/util.py":
			source => "puppet:///files/ganglia/plugins/util.py";
		"/usr/lib/ganglia/python_modules/compat.py":
			source => "puppet:///files/ganglia/plugins/compat.py";
		"/etc/ganglia/conf.d/htcpseqcheck.pyconf":
			# Disabled due to excessive memory and CPU usage -- TS
			notify => Service[gmond],
			ensure => absent;
			#require => File["/etc/ganglia/conf.d"],
			#source => "puppet:///files/ganglia/plugins/htcpseqcheck.pyconf";
	}
}

# == Class misc::monitoring::net::udp
# Sends UDP statistics to ganglia.
class misc::monitoring::net::udp {
	file {
		'/usr/lib/ganglia/python_modules/udp_stats.py':
			require => File['/usr/lib/ganglia/python_modules'],
			source => 'puppet:///files/ganglia/plugins/udp_stats.py',
			notify => Service[gmond];
		'/etc/ganglia/conf.d/udp_stats.pyconf':
			require => File["/usr/lib/ganglia/python_modules/udp_stats.py"],
			source => "puppet:///files/ganglia/plugins/udp_stats.pyconf",
			notify => Service[gmond];
	}
}

# Ganglia views that should be
# avaliable on ganglia.wikimedia.org
class misc::monitoring::views {
	require ganglia::web

	misc::monitoring::view::udp2log { 'udp2log':
		host_regex => 'locke|emery|oxygen|gadolinium',
	}
	misc::monitoring::view::kafka { 'kafka':
		kafka_broker_host_regex   => 'analytics10[12].eqiad.wmnet',
		kafka_producer_host_regex => 'analytics100[345689].eqiad.wmnet',
	}
}

# == Define misc:monitoring::view::udp2log
# Installs a ganglia::view for a group of nodes
# running udp2log.  This is just a wrapper for
# udp2log specific metrics to include in udp2log
# ganglia views.
#
# == Parameters:
# $host_regex - regex to pass to ganglia::view for matching host names in the view.
#
define misc::monitoring::view::udp2log($host_regex) {
	ganglia::view { $name:
		graphs => [
			{
				'host_regex'   => $host_regex,
				'metric_regex' => 'packet_loss_average',
			},
			{
				'host_regex'   => $host_regex,
				'metric_regex' => 'packet_loss_90th',
			},
			{
				'host_regex'   => $host_regex,
				'metric_regex' => 'drops',
				'type'         => 'stack',
			},
			{
				'host_regex'   => $host_regex,
				'metric_regex' => 'pkts_in',
				'type'         => 'stack',
			},
			{
				'host_regex'   => $host_regex,
				'metric_regex' => 'rx_queue',
			},
			{
				'host_regex'   => $host_regex,
				'metric_regex' => 'UDP_InErrors',
				'type'         => 'stack',
			},
			{
				'host_regex'   => $host_regex,
				'metric_regex' => 'UDP_RcvbufErrors',
				'type'         => 'stack',
			},
			{
				'host_regex'   => $host_regex,
				'metric_regex' => 'UDP_InDatagrams',
				'type'         => 'stack',
			},
			{
				'host_regex'   => $host_regex,
				'metric_regex' => 'UDP_SndbufErrors',
				'type'         => 'stack',
			},
			{
				'host_regex'   => $host_regex,
				'metric_regex' => 'UDP_OutDatagrams',
				'type'         => 'stack',
			},
		],
	}
}


# == Define misc:monitoring::view::kafka
# Installs a ganglia::view for a group of nodes
# running kafka broker servers.  This is just a wrapper for
# kafka specific metrics to include in kafka
#
# == Parameters:
# $kafka_broker_host_regex  - regex matching kafka broker hosts
# kafka_producer_host_regex - regex matching kafka producer hosts
#
define misc::monitoring::view::kafka($kafka_broker_host_regex, $kafka_producer_host_regex) {
	ganglia::view { $name:
		graphs => [
			{
				'host_regex'   => $kafka_broker_host_regex,
				'metric_regex' => 'kafka_network_SocketServerStats.ProduceRequestsPerSecond',
				'type'         => 'stack',
			},
			{
				'host_regex'   => $kafka_broker_host_regex,
				'metric_regex' => 'kafka_network_SocketServerStats.FetchRequestsPerSecond',
				'type'         => 'stack',
			},
			{
				'host_regex'   => $kafka_broker_host_regex,
				'metric_regex' => 'kafka_network_SocketServerStats.BytesWrittenPerSecond',
				'type'         => 'stack',
			},
			{
				'host_regex'   => $kafka_broker_host_regex,
				'metric_regex' => 'kafka_network_SocketServerStats.BytesReadPerSecond',
				'type'         => 'stack',
			},
			{
				'host_regex'   => $kafka_broker_host_regex,
				'metric_regex' => 'kafka_message_LogFlushStats.FlushesPerSecond',
				'type'         => 'stack',
			},
			{
				'host_regex'   => $kafka_producer_host_regex,
				'metric_regex' => 'kafka_producer_KafkaProducerStats-.+.ProduceRequestsPerSecond',
				'type'         => 'stack',
			},
		],
	}
}