# mediawiki udp2log instance.  Does not use monitoring.
class role::logging::mediawiki($monitor = true, $log_directory = '/srv/mw-log' ) {
    system::role { 'role::logging:mediawiki':
        description => 'MediaWiki log collector',
    }

    include base::firewall

    # Rsync archived slow-parse logs to dumps.wikimedia.org.
    # These are available for download at http://dumps.wikimedia.org/other/slow-parse/
    include ::dataset::user
    cron { 'rsync_slow_parse':
        command     => '/usr/bin/rsync -rt /a/mw-log/archive/slow-parse.log*.gz dumps.wikimedia.org::slow-parse/',
        hour        => 23,
        minute      => 15,
        environment => 'MAILTO=ops-dumps@wikimedia.org',
        user        => 'datasets',
    }

    class { 'udp2log':
        monitor          => $monitor,
        default_instance => false,
    }

    file { '/usr/local/bin/demux.py':
        mode   => '0544',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///files/misc/demux.py',
    }

    $error_processor_host = $::realm ? {
        production => 'eventlog1001.eqiad.wmnet',
        labs       => "deployment-fluoride.${::site}.wmflabs",
    }

    $logstash_host = $::realm ? {
        # TODO: Find a way to use multicast that doesn't cause duplicate
        # messages to be stored in logstash. This is a SPOF.
        production => 'logstash1001.eqiad.wmnet',
        labs       => 'deployment-logstash2.deployment-prep.eqiad.wmflabs',
    }

    $logstash_port = 8324

    udp2log::instance { 'mw':
        log_directory       =>    $log_directory,
        monitor_log_age     =>    false,
        monitor_processes   =>    false,
        monitor_packet_loss =>    false,
        template_variables  => {
            error_processor_host => $error_processor_host,
            error_processor_port => 8423,

            # forwarding to logstash
            logstash_host        => $logstash_host,
            logstash_port        => $logstash_port,
        },
    }

    # Allow rsyncing of udp2log generated files to
    # analysis hosts.
    class { 'udp2log::rsyncd':
        path => $log_directory,
    }

    cron { 'mw-log-cleanup':
        command => '/usr/local/bin/mw-log-cleanup',
        user    => 'root',
        hour    => 2,
        minute  => 0
    }

    file { '/usr/local/bin/mw-log-cleanup':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///files/misc/scripts/mw-log-cleanup',
    }

    file { '/usr/local/bin/exceptionmonitor':
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        content => template('misc/exceptionmonitor.erb'),
    }

    file { '/usr/local/bin/fatalmonitor':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///files/misc/scripts/fatalmonitor',
    }

}

# == Class role::logging::mediawiki::errors
# fluorine's udp2log instance forwards MediaWiki exceptions and fatals
# to eventlog*, as configured in templates/udp2log/filters.mw.erb. This
# role provisions a metric module that reports error counts to StatsD.
#
class role::logging::mediawiki::errors {
    system::role { 'role::logging::mediawiki::errors':
        description => 'Report MediaWiki exceptions and fatals to StatsD',
    }

    class { 'mediawiki::monitoring::errors': }

    ferm::service { 'mediawiki-exceptions-logging':
        proto  => 'tcp',
        port   => '8423',
        srange => '@resolve(fluorine.eqiad.wmnet)',
    }
}

# == Class role::logging::kafkatee::webrequest
# TODO: This needs a not-stupid name.
#
# Uses kafkatee to consume webrequest logs from kafka.
# This class does not configure any kafkatee outputs.
# To do so, you should create a new class that inherits
# from this class, and configure the outputs there.
#
class role::logging::kafkatee::webrequest {
    require role::kafka::analytics::config

    # Install kafkatee configured to consume from
    # the Analytics Kafka cluster.  The webrequest logs are
    # in json, so we output them in the format they are received.
    class { '::kafkatee':
        kafka_brokers           => $role::kafka::analytics::config::brokers_array,
        output_encoding         => 'json',
        output_format           => undef,
    }
    include kafkatee::monitoring

    # TODO: Do we need all topics for ops debugging of webrequest logs?

    # Include all webrequest topics as inputs.
    # Note:  we used offset => 'end' rather than 'stored'
    # because we don't need to backfill these files from
    # buffered kafka data if kafkatee goes down.
    # These are just logs for ops debugging.
    kafkatee::input { 'kafka-webrequest_bits':
        topic       => 'webrequest_bits',
        partitions  => '0-11',
        options     => { 'encoding' => 'json' },
        offset      => 'end',
    }
    kafkatee::input { 'kafka-webrequest_misc':
        topic       => 'webrequest_misc',
        partitions  => '0-11',
        options     => { 'encoding' => 'json' },
        offset      => 'end',
    }
    kafkatee::input { 'kafka-webrequest_mobile':
        topic       => 'webrequest_mobile',
        partitions  => '0-11',
        options     => { 'encoding' => 'json' },
        offset      => 'end',
    }
    kafkatee::input { 'kafka-webrequest_text':
        topic       => 'webrequest_text',
        partitions  => '0-11',
        options     => { 'encoding' => 'json' },
        offset      => 'end',
    }
    kafkatee::input { 'kafka-webrequest_upload':
        topic       => 'webrequest_upload',
        partitions  => '0-11',
        options     => { 'encoding' => 'json' },
        offset      => 'end',
    }

    # Declare packaged rsyslog config to ensure it isn't purged.
    file { '/etc/rsyslog.d/75-kafkatee.conf':
        ensure  => file,
        require => Class['::kafkatee'],
    }

    $log_directory              = '/srv/log'
    $webrequest_log_directory   = "${log_directory}/webrequest"
    file { [$log_directory, $webrequest_log_directory]:
        ensure      => 'directory',
        owner       => 'kafkatee',
        group       => 'kafkatee',
        require     => Class['::kafkatee'],
    }

    # if the logs in $log_directory should be rotated
    # then configure a logrotate.d script to do so.
    file { '/etc/logrotate.d/kafkatee-webrequest':
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('kafkatee/logrotate.erb'),
    }

}

# == Class role::logging::kafkatee::webrequest::ops
# Includes output filters useful for operational debugging.
#
class role::logging::kafkatee::webrequest::ops inherits role::logging::kafkatee::webrequest  {
    kafkatee::output { 'sampled-1000':
        destination => "${webrequest_log_directory}/sampled-1000.json",
        sample      => 1000,
    }

    kafkatee::output { '5xx':
        # Adding --line-buffered here ensures that the output file will only have full lines written to it.
        # Otherwise kafkatee buffers and sends to the pipe whenever it feels like, which causes grep to
        # work on non-full lines.
        destination => "/bin/grep --line-buffered '\"http_status\":\"5' >> ${webrequest_log_directory}/5xx.json",
        type        => 'pipe',
    }
}
