# SPDX-License-Identifier: Apache-2.0
# == Define: kafkatee::instance
#
# Installs and configures a kafkatee instance.
#
# == Parameters:
# $kafka_brokers             - Array of Kafka broker addresses.
# $inputs                    - Array of kafkatee input configs.  See README.
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
# $output_config             - Instruct the kafkatee instance to read or not
#                              the output configuration directory.
#                              Default: true
# $configure_rsyslog         - Add necessary configuration files for logrotate
#                              and rsyslog. The rsyslog/logrotate configuration
#                              are handled by two separate puppet modules
#                              (named rsyslog and logrotate), so setting this
#                              option to 'true' will require both of them to
#                              work properly.
#                              Default: true
#
define kafkatee::instance (
    Array[String] $kafka_brokers,
    Array[Kafkatee::Input] $inputs,
    Enum['file', 'broker', 'none'] $kafka_offset_store_method = 'file',
    Stdlib::Unixpath $kafka_offset_store_path                 = "/var/cache/kafkatee/${name}/offsets",
    Enum['smallest', 'largest', 'error'] $kafka_offset_reset  = 'largest',
    Optional[Integer] $kafka_message_max_bytes                = undef,
    String $kafka_group_id                                    = $::fqdn,
    Stdlib::Unixpath $pidfile                                 = "/var/run/kafkatee/kafkatee-${name}.pid",
    Stdlib::Unixpath $log_statistics_file                     = "/var/cache/kafkatee/${name}/kafkatee.stats.json",
    Integer[0,300] $log_statistics_interval                   = 60,
    Enum['string', 'json'] $output_encoding                   = 'string',
    Optional[String] $output_format                           = undef,
    Optional[Integer] $output_queue_size                      = undef,
    Boolean $output_config                                    = true,
    Boolean $ssl_enabled                                      = false,
    Stdlib::Unixpath $ssl_ca_location                         = $facts['puppet_config']['localcacert'],
    String $ssl_cipher_suites                                 = 'ECDHE-ECDSA-AES256-GCM-SHA384',
    String $ssl_curves_list                                   = 'P-256',
    String $ssl_sigalgs_list                                  = 'ECDSA+SHA256',
)
{
    require ::kafkatee

    file { "/etc/kafkatee/${title}.outputs":
        ensure  => 'directory',
        require => Package['kafkatee'],
    }

    file { "/var/cache/kafkatee/${title}":
        ensure  => 'directory',
        owner   => 'kafkatee',
        group   => 'kafkatee',
        require => Package['kafkatee'],
    }

    # Basic logrotate.d configuration to rotate statisitcs files for this instance.
    logrotate::conf { "kafkatee-${title}":
        content => template('kafkatee/kafkatee_instance_logrotate.erb'),
    }

    file { "/etc/kafkatee/${title}.conf":
        content => template('kafkatee/kafkatee.conf.erb'),
        require => Package['kafkatee'],
    }

    systemd::service { "kafkatee-${title}":
        content   => systemd_template('kafkatee'),
        restart   => true,
        subscribe => File["/etc/kafkatee/${title}.conf"],
    }
}
