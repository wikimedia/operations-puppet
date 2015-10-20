# == Define Class: burrow
# Burrow is a consumer offset lag monitoring tool for Kakfa
# This module helps set up a burrow service that provides a
# http endpoint to query, and will email notifications on
# consumer groups statuses.
#
#
# == Parameters
# $client_id          - The client ID string to provide to Kafka when consuming
# $zk_hosts           - Array of zookeeper host urls
# $zk_path            - The full path to the znode that is the root for the Kafka cluster
# $kafka_cluster_name - Name of the Kafka cluster
# $kafka_brokers      - Array of kafka broker urls
# $consumer_groups    - Consumer groups to be monitored to get email notifications
# $smtp_server        - SMTP server to send emails from
# $from_email         - From email address for notification
# $to_email           - Comma separated email addresses to send email notification to

class burrow (
    $ensure = 'present',
    $client_id = 'burrow-client',
    $zk_hosts,
    $zk_path,
    $kafka_cluster_name,
    $kafka_brokers,
    $consumer_groups,
    $smtp_server,
    $from_email,
    $to_emails,
)
{
    require_package('golang-burrow')

    # The config_dir is already assumed to exist when the package is installed
    $config_dir = '/etc/burrow'

    file { "${config_dir}/burrow.cfg":
        ensure  => $ensure,
        content => template('burrow/burrow.cfg.erb'),
    }

    file { "${config_dir}/logging.cfg":
        ensure => $ensure,
        source  => 'puppet:///modules/burrow/logging.cfg',
    }

    file { "${config_dir}/default-email.tmpl":
        ensure => $ensure,
        source  => 'puppet:///modules/burrow/default-email.tmpl',
    }

    service { "burrow":
        ensure => $ensure,
        enable => true,
    }
}
