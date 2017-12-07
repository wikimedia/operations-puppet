# == Class role::logging::kafkatee::webrequest
# TODO: This needs a not-stupid name.
#
# Uses kafkatee to consume webrequest logs from kafka.
# This class does not configure any kafkatee outputs.
# To do so, you should create a new class that inherits
# from this class, and configure the outputs there.
#
class role::logging::kafkatee::webrequest::base {

    $kafka_config = kafka_config('analytics')

    # Install kafkatee configured to consume from
    # the Analytics Kafka cluster.  The webrequest logs are
    # in json, so we output them in the format they are received.
    class { '::kafkatee':
        kafka_brokers   => $kafka_config['brokers']['array'],
        output_encoding => 'json',
        output_format   => undef,
    }

    # Include all webrequest topics as inputs.
    # Note:  we used offset => 'end' rather than 'stored'
    # because we don't need to backfill these files from
    # buffered kafka data if kafkatee goes down.
    # These are just logs for ops debugging.
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
    logrotate::conf { 'kafkatee-webrequest':
        ensure  => 'present',
        content => template('role/logging/kafkatee_logrotate.erb'),
    }

}
