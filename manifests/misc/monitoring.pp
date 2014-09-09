# misc/monitoring.pp

class misc::monitoring::htcp-loss {
    system::role { 'misc::monitoring::htcp-loss': description => 'HTCP packet loss monitor' }

    File {
        require => File['/usr/lib/ganglia/python_modules'],
        notify => Service['gmond']
    }

    # Ganglia
    file {
        '/usr/lib/ganglia/python_modules/htcpseqcheck.py':
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            source  => 'puppet:///files/ganglia/plugins/htcpseqcheck.py';
        '/usr/lib/ganglia/python_modules/htcpseqcheck_ganglia.py':
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            source  => 'puppet:///files/ganglia/plugins/htcpseqcheck_ganglia.py';
        '/usr/lib/ganglia/python_modules/util.py':
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            source  => 'puppet:///files/ganglia/plugins/util.py';
        '/usr/lib/ganglia/python_modules/compat.py':
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            source  => 'puppet:///files/ganglia/plugins/compat.py';
        '/etc/ganglia/conf.d/htcpseqcheck.pyconf':
            # Disabled due to excessive memory and CPU usage -- TS
            # owner   => 'root',
            # group   => 'root',
            # mode    => '0444',
            notify  => Service['gmond'],
            ensure  => absent;
            # require => File["/etc/ganglia/conf.d"],
            # source  => "puppet:///files/ganglia/plugins/htcpseqcheck.pyconf";
    }
}

# == Class misc::monitoring::net::udp
# Sends UDP statistics to ganglia.
#
class misc::monitoring::net::udp {
    file {
        '/usr/lib/ganglia/python_modules/udp_stats.py':
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            source  => 'puppet:///files/ganglia/plugins/udp_stats.py',
            require => File['/usr/lib/ganglia/python_modules'],
            notify  => Service['gmond'];
        '/etc/ganglia/conf.d/udp_stats.pyconf':
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            source  => 'puppet:///files/ganglia/plugins/udp_stats.pyconf',
            require => File['/usr/lib/ganglia/python_modules/udp_stats.py'],
            notify  => Service['gmond'];
    }
}

# == Class misc::monitoring::kraken::loss
# Checks recently generated webrequest loss statistics in
# Kraken HDFS and sends the average loss percentage to ganglia.
#
class misc::monitoring::kraken::loss {
    file {
        '/usr/lib/ganglia/python_modules/kraken_webrequest_loss.py':
            require => File['/usr/lib/ganglia/python_modules'],
            source  => 'puppet:///files/ganglia/plugins/kraken_webrequest_loss.py',
            notify  => Service['gmond'];
        '/etc/ganglia/conf.d/udp_stats.pyconf':
            require => File['/usr/lib/ganglia/python_modules/kraken_webrequest_loss.py'],
            source  => 'puppet:///files/ganglia/plugins/kraken_webrequest_loss.pyconf',
            notify  => Service['gmond'];
    }

    # Set up icinga monitoring of Kraken HDFS data loss.
    monitor_service { 'kraken_webrequest_loss_average_positive':
        description           => 'webrequest_loss_average_positive',
        check_command         => 'check_kraken_webrequest_loss_positive!2!8',
        contact_group         => 'analytics',
    }
    # It is possible to have negative data loss.  This would mean that
    # we are receiving duplicates log lines.  We need alerts for this too.
    monitor_service { 'kraken_webrequest_loss_average_negative':
        description           => 'webrequest_loss_average_negative',
        check_command         => 'check_kraken_webrequest_loss_negative!-2!-8',
        contact_group         => 'analytics',
    }
}

# Ganglia views that should be
# avaliable on ganglia.wikimedia.org
class misc::monitoring::views {
    require ganglia::web
    include role::analytics::kafka::config

    misc::monitoring::view::udp2log { 'udp2log':
        host_regex => 'oxygen|erbium|gadolinium',
    }

    $kafka_log_disks_regex = join($::role::analytics::kafka::config::log_disks, '|')
    $kafka_broker_host_regex = join($::role::analytics::kafka::config::brokers_array, '|')
    misc::monitoring::view::kafka { 'kafka':
        kafka_broker_host_regex   => $kafka_broker_host_regex,
        kafka_log_disks_regex     => $kafka_log_disks_regex,
    }
    misc::monitoring::view::varnishkafka { 'webrequest':
        topic_regex => 'webrequest_.+',
    }
    class { 'misc::monitoring::view::kafkatee':
        kafkatee_host_regex => 'analytics1003.eqiad.wmnet',
    }

    class { 'misc::monitoring::view::hadoop':
        master       => 'analytics1010.eqiad.wmnet',
        worker_regex => 'analytics10(11|[3-9]|20).eqiad.wmnet',
    }

    include misc::monitoring::views::dns
}

class misc::monitoring::views::dns {
    $auth_dns_host_regex = '^(rubidium|mexia|baham|eeden.esams).wikimedia.org$'
    $rec_dns_host_regex = '^(chromium|hydrogen).wikimedia.org$'

    ganglia::view { 'authoritative_dns':
        ensure => 'present',
        graphs => [
            {
            'title'         => 'DNS UDP Requests',
            'host_regex'    => $auth_dns_host_regex,
            'metric_regex'  => '^gdnsd_udp_reqs$',
            'type'          => 'stack',
            },
            {
            'title'         => 'DNS TCP Requests',
            'host_regex'    => $auth_dns_host_regex,
            'metric_regex'  => '^gdnsd_tcp_reqs$',
            'type'          => 'stack',
            },
            {
            'title'         => 'DNS NXDOMAIN',
            'host_regex'    => $auth_dns_host_regex,
            'metric_regex'  => '^gdnsd_stats_nxdomain$',
            'type'          => 'stack',
            },
            {
            'title'         => 'DNS REFUSED',
            'host_regex'    => $auth_dns_host_regex,
            'metric_regex'  => '^gdnsd_stats_refused$',
            'type'          => 'stack',
            },
            {
            'title'         => 'DNS queries over IPv6',
            'host_regex'    => $auth_dns_host_regex,
            'metric_regex'  => '^gdnsd_stats_v6$',
            'type'          => 'stack',
            },
            {
            'title'         => 'DNS EDNS Client Subnet requests',
            'host_regex'    => $auth_dns_host_regex,
            'metric_regex'  => '^gdnsd_stats_edns_clientsub$',
            'type'          => 'stack',
            },
        ]
    }

    ganglia::view { 'recursive_dns':
        ensure => 'present',
        graphs => [
            {
            'title'         => 'DNS Outgoing queries',
            'host_regex'    => $rec_dns_host_regex,
            'metric_regex'  => '^pdns_all-outqueries$',
            'type'          => 'stack',
            },
            {
            'title'         => 'DNS Answers',
            'host_regex'    => $rec_dns_host_regex,
            'metric_regex'  => '^pdns_answers.*$',
            'type'          => 'stack',
            },
            {
            'title'         => 'DNS cache',
            'host_regex'    => $rec_dns_host_regex,
            'metric_regex'  => '^pdns_cache-.*$',
            'type'          => 'stack',
            },
            {
            'title'         => 'DNS IPv6 Outgoing queries',
            'host_regex'    => $rec_dns_host_regex,
            'metric_regex'  => '^pdns_ipv6-outqueries$',
            'type'          => 'stack',
            },
            {
            'title'         => 'DNS Incoming queries',
            'host_regex'    => $rec_dns_host_regex,
            'metric_regex'  => '^pdns_questions$',
            'type'          => 'stack',
            },
            {
            'title'         => 'DNS Servfails',
            'host_regex'    => $rec_dns_host_regex,
            'metric_regex'  => '^pdns_servfail-asnwers$',
            'type'          => 'stack',
            },
            {
            'title'         => 'DNS NXDOMAIN',
            'host_regex'    => $rec_dns_host_regex,
            'metric_regex'  => '^pdns_nxdomain-asnwers$',
            'type'          => 'stack',
            },
        ]
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
define misc::monitoring::view::udp2log($host_regex, $ensure = 'present') {
    ganglia::view { $name:
        ensure => $ensure,
        graphs => [
            {
                'host_regex'   => $host_regex,
                'metric_regex' => '^packet_loss_average$',
            },
            {
                'host_regex'   => $host_regex,
                'metric_regex' => '^packet_loss_90th$',
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
# $kafka_broker_host_regex   - regex matching kafka broker hosts
# $log_disk_regex            - regex matching disks that have Kafka log directories
#
define misc::monitoring::view::kafka($kafka_broker_host_regex, $kafka_log_disks_regex = '.+', $ensure = 'present') {
    ganglia::view { $name:
        ensure => $ensure,
        graphs => [
            # Messages In
            {
                'host_regex'   => $kafka_broker_host_regex,
                'metric_regex' => 'kafka.server.BrokerTopicMetrics.+-MessagesInPerSec.OneMinuteRate',
                'type'         => 'stack',
            },

            # Bytes In
            {
                'host_regex'   => $kafka_broker_host_regex,
                'metric_regex' => 'kafka.server.BrokerTopicMetrics.+-BytesInPerSec.OneMinuteRate',
                'type'         => 'stack',
            },

            # BytesOut
            {
                'host_regex'   => $kafka_broker_host_regex,
                'metric_regex' => 'kafka.server.BrokerTopicMetrics.+-BytesOutPerSec.OneMinuteRate',
                'type'         => 'stack',
            },

            # Produce Requests
            {
                'host_regex'   => $kafka_broker_host_regex,
                'metric_regex' => 'kafka.network.RequestMetrics.Produce-RequestsPerSec.OneMinuteRate',
                'type'         => 'stack',
            },

            # Failed Produce Requests
            {
                'host_regex'   => $kafka_broker_host_regex,
                'metric_regex' => 'kafka.server.BrokerTopicMetrics.+-FailedProduceRequestsPerSec.OneMinuteRate',
                'type'         => 'stack',
            },

            # Replica Max Lag
            {
                'host_regex'   => $kafka_broker_host_regex,
                'metric_regex' => 'kafka.server.ReplicaFetcherManager.Replica-MaxLag.Value',
                'type'         => 'line',
            },
            # Under Replicated Partitions
            {
                'host_regex'   => $kafka_broker_host_regex,
                'metric_regex' => 'kafka.server.ReplicaManager.UnderReplicatedPartitions.Value',
                'type'         => 'line',
            },

            # ISR Shrinks
            {
                'host_regex'   => $kafka_broker_host_regex,
                'metric_regex' => 'kafka.server.ReplicaManager.ISRShrinks.FiveMinuteRate',
                'type'         => 'line',
            },
            # ISR Expands
            {
                'host_regex'   => $kafka_broker_host_regex,
                'metric_regex' => 'kafka.server.ReplicaManager.ISRExpands.FiveMinuteRate',
                'type'         => 'line',
            },
            # /proc/diskstat bytes written per second
            {
                'host_regex'   => $kafka_broker_host_regex,
                'metric_regex' => "diskstat_(${kafka_log_disks_regex})_write_bytes_per_sec",
                'type'         => 'stack',
            },
            # /proc/diskstat bytes read per second
            {
                'host_regex'   => $kafka_broker_host_regex,
                'metric_regex' => "diskstat_(${kafka_log_disks_regex})_read_bytes_per_sec",
                'type'         => 'stack',
            },
            # /proc/diskstat disk utilization %
            {
                'host_regex'   => $kafka_broker_host_regex,
                'metric_regex' => "diskstat_(${kafka_log_disks_regex})_percent_io_time",
                'type'         => 'line',
            },
            # /proc/diskstat IO time
            {
                'host_regex'   => $kafka_broker_host_regex,
                'metric_regex' => "diskstat_(${kafka_log_disks_regex})_io_time",
                'type'         => 'line',
            },
            # 15 minute load average
            {
                'host_regex'   => $kafka_broker_host_regex,
                'metric_regex' => 'load_fifteen',
                'type'         => 'line',
            },
            # IO wait
            {
                'host_regex'   => $kafka_broker_host_regex,
                'metric_regex' => 'cpu_wio',
                'type'         => 'line',
            },
        ],
    }
}


# == Define misc::monitoring::view::varnishkafka
#
define misc::monitoring::view::varnishkafka($varnishkafka_host_regex = '(amssq|cp).+', $topic_regex = '.+', $ensure = 'present') {
    ganglia::view { "varnishkafka-${title}":
        ensure => $ensure,
        graphs => [
            # delivery report error rate
            {
                'host_regex'   => $varnishkafka_host_regex,
                'metric_regex' => 'kafka.varnishkafka\.kafka_drerr.per_second',
                'type'         => 'line',
            },
            # delivery report errors.
            # drerr is important, but seems to happen in bursts.
            # let's show the total drerr in the view as well.
            {
                'host_regex'   => $varnishkafka_host_regex,
                'metric_regex' => 'kafka.varnishkafka\.kafka_drerr$',
                'type'         => 'line',
            },
            # transaction error rate
            {
                'host_regex'   => $varnishkafka_host_regex,
                'metric_regex' => 'kafka.varnishkafka\.txerr.per_second',
                'type'         => 'line',
            },

            # round trip time average
            {
                'host_regex'   => $varnishkafka_host_regex,
                'metric_regex' => 'kafka.rdkafka.brokers..+\.rtt\.avg',
                'type'         => 'line',
            },

            # Queues:
            #   msgq -> xmit_msgq -> outbuf -> waitresp
            # message queue count
            {
                'host_regex'   => $varnishkafka_host_regex,
                'metric_regex' => "kafka.rdkafka.topics.${topic_regex}\\.msgq_cnt",
                'type'         => 'line',
            },
            # transmit message queue count
            {
                'host_regex'   => $varnishkafka_host_regex,
                'metric_regex' => "kafka.rdkafka.topics.${topic_regex}\\.xmit_msgq_cnt",
                'type'         => 'line',
            },
            # output buffer queue count
            {
                'host_regex'   => $varnishkafka_host_regex,
                'metric_regex' => 'kafka.rdkafka.brokers..+\.outbuf_cnt',
                'type'         => 'line',
            },
            # waiting for response buffer count
            {
                'host_regex'   => $varnishkafka_host_regex,
                'metric_regex' => 'kafka.rdkafka.brokers..+\.waitresp_cnt',
                'type'         => 'line',
            },

            # transaction bytes rate
            {
                'host_regex'   => $varnishkafka_host_regex,
                'metric_regex' => "kafka.rdkafka.topics.${topic_regex}\\.txbytes.per_second",
                'type'         => 'stack',
            },
            # transaction messages rate
            {
                'host_regex'   => $varnishkafka_host_regex,
                'metric_regex' => "kafka.rdkafka.topics.${topic_regex}\\.txmsgs.per_second",
                'type'         => 'stack',
            },
        ],
    }
}


# == Class misc::monitoring::view::kafkatee
#
class misc::monitoring::view::kafkatee($kafkatee_host_regex, $topic_regex = '.+', $ensure = 'present') {
    ganglia::view { 'kafkatee':
        ensure => $ensure,
        graphs => [
            # receive transctions per second rate
            {
                'host_regex'   => $kafkatee_host_regex,
                'metric_regex' => 'kafka.rdkafka.brokers..+\.rx\.per_second',
                'type'         => 'stack',
            },
            # receive bytes per second rate
            {
                'host_regex'   => $kafkatee_host_regex,
                'metric_regex' => 'kafka.rdkafka.brokers..+\.rxbytes\.per_second',
                'type'         => 'stack',
            },
            # round trip time average
            {
                'host_regex'   => $kafkatee_host_regex,
                'metric_regex' => 'kafka.rdkafka.brokers..+\.rtt\.avg',
                'type'         => 'line',
            },
            # next_offset.per_second - rate at which offset is updated,
            # meaning how many offsets per second are read
            {
                'host_regex'   => $kafkatee_host_regex,
                'metric_regex' => "kafka.rdkafka.topics.${topic_regex}\\.next_offset.per_second",
                'type'         => 'stack',
            },
        ],
    }
}


# == Class misc::monitoring::view::hadoop
#
class misc::monitoring::view::hadoop($master, $worker_regex, $ensure = 'present') {
    ganglia::view { 'hadoop':
        ensure => $ensure,
        graphs => [
            # ResourceManager active applications
            {
                'host_regex'   => $master,
                'metric_regex' => 'Hadoop.ResourceManager.QueueMetrics.*ActiveApplications',
                'type'         => 'stack',
            },
            # ResourceManager failed applications
            {
                'host_regex'   => $master,
                'metric_regex' => 'Hadoop.ResourceManager.QueueMetrics.*AppsFailed',
                'type'         => 'stack',
            },
            # NodeManager containers running
            {
                'host_regex'   => $worker_regex,
                'metric_regex' => 'Hadoop.NodeManager.NodeManagerMetrics.ContainersRunning',
                'type'         => 'stack',
            },
            # NodeManager Allocated Memeory GB
            {
                'host_regex'   => $worker_regex,
                'metric_regex' => 'Hadoop.NodeManager.NodeManagerMetrics.AllocatedGB',
                'type'         => 'stack',
            },
            # Worker Node bytes_in
            {
                'host_regex'   => $worker_regex,
                'metric_regex' => 'bytes_in',
                'type'         => 'stack',
            },
            # Worker Node bytes_out
            {
                'host_regex'   => $worker_regex,
                'metric_regex' => 'bytes_out',
                'type'         => 'stack',
            },
            # Primary NameNode File activity
            {
                'host_regex'   => $master,
                'metric_regex' => 'Hadoop.NameNode.NameNodeActivity.Files(Created|Deleted|Renamed|Appended)',
                'type'         => 'line',
            },
            # Worker Node /proc/diskstat bytes written per second
            {
                'host_regex'   => $worker_regex,
                'metric_regex' => "diskstat_(${kafka_log_disks_regex})_write_bytes_per_sec",
                'type'         => 'stack',
            },
            # /proc/diskstat bytes read per second
            {
                'host_regex'   => $worker_regex,
                'metric_regex' => "diskstat_(${kafka_log_disks_regex})_read_bytes_per_sec",
                'type'         => 'stack',
            },
            # Worker Node /proc/diskstat disk utilization %
            {
                'host_regex'   => $worker_regex,
                'metric_regex' => "diskstat_(${kafka_log_disks_regex})_percent_io_time",
                'type'         => 'line',
            },
            # Worker Node /proc/diskstat IO time
            {
                'host_regex'   => $worker_regex,
                'metric_regex' => "diskstat_(${kafka_log_disks_regex})_io_time",
                'type'         => 'line',
            },
            # Worker Node 15 minute load average
            {
                'host_regex'   => $worker_regex,
                'metric_regex' => 'load_fifteen',
                'type'         => 'line',
            },
            # Worker Node IO wait
            {
                'host_regex'   => $worker_regex,
                'metric_regex' => 'cpu_wio',
                'type'         => 'line',
            },
        ],
    }
}






# == Class misc::monitoring::view::analytics::data
# View for analytics data flow.
# This is a class instead of a define because it is specific enough to never need
# multiple instances.
#
# == Parameters
# $hdfs_stat_host            - host on which the webrequest_loss_percentage metric is gathered.
# $kafka_broker_host_regex   - regex matching kafka broker hosts
# $kafka_producer_host_regex - regex matching kafka producer hosts, this is the same as upd2log hosts
#
class misc::monitoring::view::analytics::data($hdfs_stat_host, $kafka_broker_host_regex, $kafka_producer_host_regex, $ensure = 'present') {
    ganglia::view { 'analytics-data':
        ensure => $ensure,
        graphs => [
            {
                'host_regex'   => $kafka_producer_host_regex,
                'metric_regex' => '^packet_loss_average$',
            },
            {
                'host_regex'   => $kafka_producer_host_regex,
                'metric_regex' => 'udp2log_kafka_producer_.+.AsyncProducerEvents',
                'type'         => 'stack',
            },
            {
                'host_regex'   => $kafka_broker_host_regex,
                'metric_regex' => 'kafka_network_SocketServerStats.ProduceRequestsPerSecond',
                'type'         => 'stack',
            },
            {
                'host_regex'   => $hdfs_stat_host,
                'metric_regex' => 'webrequest_loss_average',
            },
        ],
    }
}
