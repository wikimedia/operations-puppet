
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
        proto  => 'udp',
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

    $kafka_config = kafka_config('analytics')

    # Install kafkatee configured to consume from
    # the Analytics Kafka cluster.  The webrequest logs are
    # in json, so we output them in the format they are received.
    class { '::kafkatee':
        kafka_brokers   => $kafka_config['brokers']['array'],
        output_encoding => 'json',
        output_format   => undef,
    }
    include kafkatee::monitoring

    # TODO: Do we need all topics for ops debugging of webrequest logs?

    # Include all webrequest topics as inputs.
    # Note:  we used offset => 'end' rather than 'stored'
    # because we don't need to backfill these files from
    # buffered kafka data if kafkatee goes down.
    # These are just logs for ops debugging.
    kafkatee::input { 'kafka-webrequest_bits':
        topic      => 'webrequest_bits',
        partitions => '0-11',
        options    => {
            'encoding' => 'json',
        },
        offset     => 'end',
    }
    kafkatee::input { 'kafka-webrequest_misc':
        topic      => 'webrequest_misc',
        partitions => '0-11',
        options    => {
            'encoding' => 'json',
        },
        offset     => 'end',
    }
    kafkatee::input { 'kafka-webrequest_mobile':
        topic      => 'webrequest_mobile',
        partitions => '0-11',
        options    => {
            'encoding' => 'json',
        },
        offset     => 'end',
    }
    kafkatee::input { 'kafka-webrequest_text':
        topic      => 'webrequest_text',
        partitions => '0-23',
        options    => {
            'encoding' => 'json',
        },
        offset     => 'end',
    }
    kafkatee::input { 'kafka-webrequest_upload':
        topic      => 'webrequest_upload',
        partitions => '0-23',
        options    => {
            'encoding' => 'json',
        },
        offset     => 'end',
    }

    # Declare packaged rsyslog config to ensure it isn't purged.
    file { '/etc/rsyslog.d/75-kafkatee.conf':
        ensure  => file,
        require => Class['::kafkatee'],
    }

    $log_directory              = '/srv/log'
    $webrequest_log_directory   = "${log_directory}/webrequest"
    file { [$log_directory, $webrequest_log_directory]:
        ensure  => 'directory',
        owner   => 'kafkatee',
        group   => 'kafkatee',
        require => Class['::kafkatee'],
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
