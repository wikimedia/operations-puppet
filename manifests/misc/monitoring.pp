# misc/monitoring.pp

class misc::monitoring::htcp-loss {
    system::role { "misc::monitoring::htcp-loss": description => "HTCP packet loss monitor" }

    File {
        require => File["/usr/lib/ganglia/python_modules"],
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
            #owner   => 'root',
            #group   => 'root',
            #mode    => '0444',
            notify  => Service['gmond'],
            ensure  => absent;
            #require => File["/etc/ganglia/conf.d"],
            #source  => "puppet:///files/ganglia/plugins/htcpseqcheck.pyconf";
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
            source => 'puppet:///files/ganglia/plugins/kraken_webrequest_loss.py',
            notify => Service['gmond'];
        '/etc/ganglia/conf.d/udp_stats.pyconf':
            require => File["/usr/lib/ganglia/python_modules/kraken_webrequest_loss.py"],
            source => "puppet:///files/ganglia/plugins/kraken_webrequest_loss.pyconf",
            notify => Service['gmond'];
    }

    # Set up icinga monitoring of Kraken HDFS data loss.
    monitor_service { "kraken_webrequest_loss_average_positive":
        description           => "webrequest_loss_average_positive",
        check_command         => "check_kraken_webrequest_loss_positive!2!8",
        contact_group         => "analytics",
    }
    # It is possible to have negative data loss.  This would mean that
    # we are receiving duplicates log lines.  We need alerts for this too.
    monitor_service { "kraken_webrequest_loss_average_negative":
        description           => "webrequest_loss_average_negative",
        check_command         => "check_kraken_webrequest_loss_negative!-2!-8",
        contact_group         => "analytics",
    }
}

# Ganglia views that should be
# avaliable on ganglia.wikimedia.org
class misc::monitoring::views {
    require ganglia::web

    misc::monitoring::view::udp2log { 'udp2log':
        host_regex => 'emery|oxygen|erbium',
    }

    misc::monitoring::view::kafka { 'kafka':
        kafka_broker_host_regex   => 'analytics102[12].*',
    }
    class { 'misc::monitoring::view::varnishkafka': }

    class { 'misc::monitoring::view::navigation_timing': }
    class { 'misc::monitoring::view::static_assets': }
    class { 'misc::monitoring::view::bits_ttfb': }
    class { 'misc::monitoring::view::visual_editor': }

    class { 'misc::monitoring::view::hadoop':
        master       => 'analytics1010.eqiad.wmnet',
        worker_regex => 'analytics10(1[1-9]|20).eqiad.wmnet',
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
#
define misc::monitoring::view::kafka($kafka_broker_host_regex, $ensure = 'present') {
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

            # Under Replicated Partitions
            {
                'host_regex'   => $kafka_broker_host_regex,
                'metric_regex' => 'kafka.server.ReplicaManager.UnderReplicatedPartitions.Value',
                'type'         => 'line',
            },
        ],
    }
}

# == Class misc::monitoring::view::varnishkafka
#
class misc::monitoring::view::varnishkafka($varnishkafka_host_regex = 'cp.+', $ensure = 'present') {
    ganglia::view { 'varnishkafka':
        ensure => $ensure,
        graphs => [
            # delivery report errors rate
            {
                'host_regex'   => $varnishkafka_host_regex,
                'metric_regex' => 'kafka.varnishkafka\.kafka_drerr.per_second',
                'type'         => 'stack',
            },
            # delivery report errors.
            # drerr is important, but seems to happen in bursts.
            # let's show the total drerr in the view as well.
            {
                'host_regex'   => $varnishkafka_host_regex,
                'metric_regex' => 'kafka.varnishkafka\.kafka_drerr$',
                'type'         => 'stack',
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
                'metric_regex' => 'kafka.rdkafka.topics..+\.msgq_cnt',
                'type'         => 'stack',
            },
            # transmit message queue count
            {
                'host_regex'   => $varnishkafka_host_regex,
                'metric_regex' => 'kafka.rdkafka.topics..+\.xmit_msgq_cnt',
                'type'         => 'stack',
            },
            # output buffer queue count
            {
                'host_regex'   => $varnishkafka_host_regex,
                'metric_regex' => 'kafka.rdkafka.brokers..+\.outbuf_cnt',
                'type'         => 'stack',
            },
            # waiting for response buffer count
            {
                'host_regex'   => $varnishkafka_host_regex,
                'metric_regex' => 'kafka.rdkafka.brokers..+\.waitresp_cnt',
                'type'         => 'stack',
            },

            # transaction bytes rate
            {
                'host_regex'   => $varnishkafka_host_regex,
                'metric_regex' => 'kafka.rdkafka.topics..+\.txbytes.per_second',
                'type'         => 'stack',
            },
            # transaction messages rate
            {
                'host_regex'   => $varnishkafka_host_regex,
                'metric_regex' => 'kafka.rdkafka.topics..+\.txmsgs.per_second',
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
                'type'         => 'stacked',
            },
            # ResourceManager failed applications
            {
                'host_regex'   => $master,
                'metric_regex' => 'Hadoop.ResourceManager.QueueMetrics.*AppsFailed',
                'type'         => 'stacked',
            },
            # NodeManager containers running
            {
                'host_regex'   => $worker_regex,
                'metric_regex' => 'Hadoop.NodeManager.NodeManagerMetrics.ContainersRunning',
                'type'         => 'stacked',
            },
            # NodeManager Allocated Memeory GB
            {
                'host_regex'   => $worker_regex,
                'metric_regex' => 'Hadoop.NodeManager.NodeManagerMetrics.AllocatedGB',
                'type'         => 'stacked',
            },
            # Worker Node bytes_in
            {
                'host_regex'   => $worker_regex,
                'metric_regex' => 'bytes_in',
                'type'         => 'stacked',
            },
            # Worker Node bytes_out
            {
                'host_regex'   => $worker_regex,
                'metric_regex' => 'bytes_out',
                'type'         => 'stacked',
            },
            # Primary NameNode File activity
            {
                'host_regex'   => $master,
                'metric_regex' => 'Hadoop.NameNode.NameNodeActivity.Files(Created|Deleted|Renamed|Appended)',
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


# == Class: misc::monitoring::view::navigation_timing
#
# A Ganglia view of user-perceived latency measurements, collected via
# the NavigationTiming extension (https://www.mediawiki.org/wiki/NavigationTiming).
#
class misc::monitoring::view::navigation_timing {
    ganglia::view { 'Navigation Timing':
        graphs => [
            {
                title        => 'mediaWikiLoadComplete: startup.js to window.onload',
                host_regex   => 'client-side',
                metric_regex => '^browser.mediaWikiLoadComplete.(desktop|mobile)_median$',
            },
            {
                title        => 'totalPageLoadTime: navStart to loadEventEnd',
                host_regex   => 'client-side',
                metric_regex => '^browser.totalPageLoadTime.(desktop|mobile)_median$',
            },
            {
                title        => 'pageSpeed: domInteractive to loadEventEnd',
                host_regex   => 'client-side',
                metric_regex => '^browser.pageSpeed.(desktop|mobile)_median$',
            },
            {
                title        => 'DNS: domainLookupStart to domainLookupEnd',
                host_regex   => 'client-side',
                metric_regex => '^browser.dnsLookup.(desktop|mobile)_median$',
            },
            {
                title        => 'Connecting: connectStart to connectEnd',
                host_regex   => 'client-side',
                metric_regex => '^browser.connecting.(desktop|mobile)_median$',
            },
            {
                title        => 'Sending: navStart to fetchStart',
                host_regex   => 'client-side',
                metric_regex => '^browser.sending.(desktop|mobile)_median$',
            },
            {
                title        => 'Waiting: requestStart to responseStart',
                host_regex   => 'client-side',
                metric_regex => '^browser.waiting.(desktop|mobile)_median$',
            },
            {
                title        => 'Receiving: responseStart to responseEnd',
                host_regex   => 'client-side',
                metric_regex => '^browser.receiving.(desktop|mobile)_median$',
            },
            {
                title        => 'Rendering: responseEnd to loadEventEnd',
                host_regex   => 'client-side',
                metric_regex => '^browser.rendering.(desktop|mobile)_median$',
            },
            {
                title        => 'Loading: navStart to loadEventStart',
                host_regex   => 'client-side',
                metric_regex => '^browser.loading.(desktop|mobile)_median$',
            },
            {
                title        => 'Redirecting: redirectStart to redirectEnd',
                host_regex   => 'client-side',
                metric_regex => '^browser.redirecting.(desktop|mobile)_median$',
            },
        ],
    }
}


# == Class: misc::monitoring::view::visual_editor
#
# Performance measurements from VisualEditor.
#
class misc::monitoring::view::visual_editor {
    ganglia::view { 'VisualEditor':
        graphs => [
            {
                title        => 'VisualEditor: DOM save',
                host_regex   => 'client-side',
                metric_regex => '^browser.ve.dom.save_median$',
            },
            {
                title        => 'VisualEditor: DOM retrieve',
                host_regex   => 'client-side',
                metric_regex => '^browser.ve.dom.retrieve_*',
            },
        ],
    }
}


# == Class: misc::monitoring::view::bits_ttfb
#
# A Ganglia view of TTFB (time to first byte) timing data obtained via
# the Navigation Timing API.
#
class misc::monitoring::view::bits_ttfb {
    ganglia::view { 'Bits TTFB':
        graphs => [
            {
                title        => 'Bits time to first byte: ULSFO',
                host_regex   => 'client-side',
                metric_regex => '^browser.waiting.cp4.+_median$',
            },
            {
                title        => 'Bits time to first byte: ESAMS',
                host_regex   => 'client-side',
                metric_regex => '^browser.waiting.cp3.+_median$',
            },
            {
                title        => 'Bits time to first byte: EQIAD',
                host_regex   => 'client-side',
                metric_regex => '^browser.waiting.cp1.+_median$',
            },
        ],
    }
}


# == Class: misc::monitoring::view::static_assets
#
# A Ganglia view of the size (in bytes and number of discrete requests)
# of the static asset paylod of some popular Wikimedia wikis.
#
class misc::monitoring::view::static_assets {
    ganglia::view { 'Static assets':
        graphs => [
            {
                title        => 'Main page JavaScript byte payload',
                host_regex   => 'client-side',
                metric_regex => '^assets_javascript_bytes_*',
            },
            {
                title        => 'Main page JavaScript requests',
                host_regex   => 'client-side',
                metric_regex => '^assets_javascript_requests_*',
            },
            {
                title        => 'Main page CSS byte payload',
                host_regex   => 'client-side',
                metric_regex => '^assets_css_bytes_*',
            },
            {
                title        => 'Main page CSS requests',
                host_regex   => 'client-side',
                metric_regex => '^assets_css_requests_*',
            },
            {
                title        => 'Main page CSS rules',
                host_regex   => 'client-side',
                metric_regex => '^assets_css_rules_*',
            },
            {
                title        => 'Main page image byte payload',
                host_regex   => 'client-side',
                metric_regex => '^assets_image_bytes_*',
            },
            {
                title        => 'Main page image requests',
                host_regex   => 'client-side',
                metric_regex => '^assets_image_requests_*',
            },
            {
                title        => 'Main page misc. byte payload',
                host_regex   => 'client-side',
                metric_regex => '^assets_other_bytes_*',
            },
            {
                title        => 'Main page misc. requests',
                host_regex   => 'client-side',
                metric_regex => '^assets_other_requests_*',
            },
            {
                title        => 'Main page cookies set',
                host_regex   => 'client-side',
                metric_regex => '^assets_cookies_set_*',
            },
        ],
    }
}
