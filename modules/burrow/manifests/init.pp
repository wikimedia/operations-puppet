# == Define Class: burrow
# Burrow is a consumer offset lag monitoring tool for Kakfa
# This module helps set up a burrow service that provides a
# http endpoint to query, and will email notifications on
# consumer groups statuses.
#
# == Parameters
# $client_id          - The client ID string to provide to Kafka when consuming
# $httpserver_port    - Port at which to make the burrow http endpoint available
# $zookeeper_hosts    - Array of zookeeper host urls
# $zookeeper_path     - The full path to the znode that is the root for the Kafka cluster
# $kafka_cluster_name - Name of the Kafka cluster
# $kafka_brokers      - Array of kafka broker urls
# $consumer_groups    - Consumer groups to be monitored to get email notifications
# $smtp_server        - SMTP server to send emails from
# $from_email         - From email address for notification
# $to_email           - Comma separated email addresses to send email notification to

class burrow (
    $ensure = 'present',
    $client_id = 'burrow-client',
    $httpserver_port = 8000,
    $zookeeper_hosts,
    $zookeeper_path,
    $kafka_cluster_name,
    $kafka_brokers,
    $consumer_groups,
    $smtp_server,
    $from_email,
    $to_emails,
)
{
    require_package('burrow')

    file { '/etc/burrow/burrow.cfg':
        ensure  => $ensure,
        content => template('burrow/burrow.cfg.erb'),
        subscribe => File['/etc/burrow/burrow.cfg'],
    }

    service { 'burrow':
        ensure => ensure_service($ensure),
        enable => true,
    }
}
