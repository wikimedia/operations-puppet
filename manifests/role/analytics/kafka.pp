# role/analytics/kafka.pp
#
# Role classes for Analytics Kakfa nodes.
# These role classes will configure Kafka properly in either
# the Analytics labs or Analytics production environments.
#
# Usage:
#
# If you only need the Kafka package and configs to use the
# Kafka client to talk to Kafka Broker Servers:
#
#   include role::analytics::kafka::client
#
# If you want to set up a Kafka Broker Server
#   include role::analytics::kafka::server
#
class role::analytics::kafka::config {
    require role::analytics::zookeeper::config

    # This allows labs to set the $::kafka_cluster global,
    # which will conditionally select labs hosts to include
    # in a Kafka cluster.  This allows us to test cross datacenter
    # broker mirroring with multiple clusters.
    $kafka_cluster_name = $::kafka_cluster ? {
        undef     => $::site,
        default   => $::kafka_cluster,
    }

    if ($::realm == 'labs') {
        # TODO: Make hostnames configurable via labs global variables.
        $cluster = {
            'main'     => {
                'kafka-main1.pmtpa.wmflabs'     => { 'id' => 1 },
                'kafka-main2.pmtpa.wmflabs'     => { 'id' => 2 },
            },
            'external'                          => {
                'kafka-external1.pmtpa.wmflabs' => { 'id' => 10 },
            },
        }
        # labs only uses a single log_dir
        $log_dirs = ['/var/spool/kafka']
        # TODO: use variables from new ganglia module once it is finished.
        $ganglia_host   = 'aggregator1.pmtpa.wmflabs'
        $ganglia_port   = 50090

        # Use default ulimit for labs kafka
        $nofiles_ulimit = 8192
    }

    # else Kafka cluster is based on $::site.
    else {
        $cluster = {
            'eqiad'   => {
                'analytics1021.eqiad.wmnet' => { 'id' => 21 },
                'analytics1022.eqiad.wmnet' => { 'id' => 22 },
            },
            # 'ulsfo' => { },
            # 'pmtpa' => { },
            # 'esams' => { },
        }

        # production Kafka uses a bunch of JBOD log_dir mounts.
        $log_dirs = [
            '/var/spool/kafka/c/data',
            '/var/spool/kafka/d/data',
            '/var/spool/kafka/e/data',
            '/var/spool/kafka/f/data',
            '/var/spool/kafka/g/data',
            '/var/spool/kafka/h/data',
            '/var/spool/kafka/i/data',
            '/var/spool/kafka/j/data',
            '/var/spool/kafka/k/data',
            '/var/spool/kafka/l/data',
        ]
        # TODO: use variables from new ganglia module once it is finished.
        $ganglia_host   = '239.192.1.32'
        $ganglia_port   = 8649

        # Increase ulimit for production kafka.
        $nofiles_ulimit = 65536
    }

    $brokers          = $cluster[$kafka_cluster_name]
    $zookeeper_hosts  = $role::analytics::zookeeper::config::hosts_array
    $zookeeper_chroot = "/kafka/${kafka_cluster_name}"
    $zookeeper_url    = inline_template("<%= zookeeper_hosts.sort.join(',') %><%= zookeeper_chroot %>")
}

# == Class role::analytics::kafka::client
#
class role::analytics::kafka::client inherits role::analytics::kafka::config {
    # include kafka package
    include kafka

    # Let's go ahead and export a ZOOKEEPER_URL user environment variable.
    # This makes it much more convenient to run kafka commands without having
    # to specify the --zookeeper flag every time.
    file { '/etc/profile.d/kafka.sh':
        owner   => 'root',
        mode    => '0444',
        content => "# NOTE:  This file is managed by Puppet\nexport ZOOKEEPER_URL='${zookeeper_url}'",
    }
}

# == Class role::analytics::kafka::server
#
class role::analytics::kafka::server inherits role::analytics::kafka::client {
    class { '::kafka::server':
        log_dirs            => $log_dirs,
        brokers             => $brokers,
        zookeeper_hosts     => $zookeeper_hosts,
        zookeeper_chroot    => $zookeeper_chroot,
        nofiles_ulimit      => $nofiles_ulimit,
    }

    # Generate icinga alert if Kafka Server is not running.
    nrpe::monitor_service { 'kafka':
        description  => 'Kafka Broker Server',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a "kafka.Kafka /etc/kafka/server.properties"',
        require      => Class['::kafka::server'],
    }

    $jmxtrans_outfile = '/var/log/kafka/kafka-jmx.log'
    file { $jmxtrans_outfile:
        ensure  => 'present',
        owner   => 'jmxtrans',
        group   => 'jmxtrans',
        mode    => '0644',
        require => [Package['jmxtrans'], Package['kafka']]
    }

    # Include Kafka Server Jmxtrans class
    # to send Kafka Broker metrics to Ganglia.
    # We also save metrics to an logfile for easy
    # debugging.
    class { '::kafka::server::jmxtrans':
        ganglia => "${ganglia_host}:${ganglia_port}",
        outfile => $jmxtrans_outfile
    }

    # Install a logrotate.d file for the jmx.log file
    file { '/etc/logrotate.d/kafka-jmx':
        content =>
"${jmxtrans_outfile} {
    size 100M
    rotate 2
    missingok
    create 0644 jmxtrans jmxtrans
}
"
    }

    # Generate icinga alert if this jmxtrans instance is not running.
    nrpe::monitor_service { 'jmxtrans':
        description  => 'jmxtrans',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a "-jar jmxtrans-all.jar"',
        require      => Class['::kafka::server::jmxtrans'],
    }

    # Set up icinga monitoring of Kafka broker per second.
    # If this drops too low, trigger an alert.
    # These thresholds have to be manually set.
    # adjust them if you add or remove data from Kafka topics.
    monitor_ganglia { 'kafka-broker-MessagesIn':
        description => 'Kafka Broker Messages In',
        metric      => 'kafka.server.BrokerTopicMetrics.AllTopicsMessagesInPerSec.FifteenMinuteRate',
        warning     => ':1500.0',
        critical    => ':1000.0',
        require     => Class['::kafka::server::jmxtrans'],
    }
}

