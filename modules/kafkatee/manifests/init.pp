# == Class: kafkatee
#
# Installs and configures a kafkatee instance. This does not configure any
# inputs or outputs for the kafkatee instance.  You should configure them
# using the kafkatee::input and kafkatee::output defines.
#
# == Parameters:
# $kafka_brokers             - Array of Kafka broker addresses.
# $kafka_offset_store_method - Ether 'none', 'file', or 'broker'.  Default: file
# $kafka_offset_store_path   - Path in which to store consumed Kafka offsets.
#                              Default: /var/cache/kafkatee/offsets
# $kafka_offset_reset        - Where to consume from if the offset from which to
#                              consume is not on the broker, or if there is no
#                              stored offset yet.
#                              One of: smallest, largest, error.
#                              Default: largest
# $kafka_message_max_bytes   - Maximum message size.  Default: undef (4000000).
# $kafka_group_id            - Consumer group.id for this Kafka Consumer instance.
#                              Default: $fqdn
# $pidfile                   - Location of kafkatee pidfile.
#                              Default: /var/run/kafkatee/kafkatee.pid
# $log_statistics_file       - Path in which to store kafkatee .json statistics.
#                              Default: /var/cache/kafkatee/kafkatee.stats.json
# $log_statistics_interval   - How often to write statistics to
#                              $log_statistics_file.
#                              Default: 60
# $output_encoding           - If this is string and inputs are json, then the
#                              JSON input will be transformed according to
#                              $output_format before they are sent to
#                              the configured outputs.
#                              Default: string
# $output_format             - Format string with which to transform JSON data
#                              into string output.  See kafkatee.conf docs
#                              for more info.  Default: undef.
#                              Default: SEE PARAMETER
# $output_queue_size         - Maximum queue size for each output, in
#                              number of messages.
#                              Default: undef, (1000000)
# $config_file               - Main kafkatee config file.
#                              Default: /etc/kafkatee.conf
# $config_directory          - kafkatee config include directory.
#                              Default: /etc/kafkatee.d
# $configure_rsyslog         - Add necessary configuration files for logrotate
#                              and rsyslog. The rsyslog/logrotate configuration
#                              are handled by two separate puppet modules
#                              (named rsyslog and logrotate), so setting this
#                              option to 'true' will require both of them to
#                              work properly.
#                              Default: true

class kafkatee (
    $kafka_brokers,
    $kafka_offset_store_method = 'file',
    $kafka_offset_store_path   = '/var/cache/kafkatee/offsets',
    $kafka_offset_reset        = 'largest',
    $kafka_message_max_bytes   = undef,
    $kafka_group_id            = $::fqdn,
    $pidfile                   = '/var/run/kafkatee/kafkatee.pid',
    $log_statistics_file       = '/var/cache/kafkatee/kafkatee.stats.json',
    $log_statistics_interval   = 60,
    $output_encoding           = 'string',
    $output_format             = undef,
    $output_queue_size         = undef,
    $configure_rsyslog         = true,
)
{
    package { 'kafkatee':
        ensure => 'installed',
    }

    file { '/etc/kafkatee.conf':
        content => template('kafkatee/kafkatee.conf.erb'),
        require => Package['kafkatee'],
    }

    if $configure_rsyslog {
        # Basic logrotate.d configuration to rotate /var/log/kafkatee.log
        logrotate::conf { 'kafkatee':
            source => 'puppet:///modules/kafkatee/kafkatee_logrotate',
        }
        # Basic rsyslog configuration to create /var/log/kafkatee.log
        rsyslog::conf { 'kafkatee':
            source   => 'puppet:///modules/kafkatee/kafkatee_rsyslog.conf',
            priority => 70,
        }
    }

    service { 'kafkatee':
        ensure     => 'running',
        # lint:ignore:quoted_booleans
        hasrestart => 'true',
        # lint:endignore
        subscribe  => File['/etc/kafkatee.conf'],
    }
}
