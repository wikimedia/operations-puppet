# == Define Class: burrow
# Burrow is a consumer offset lag monitoring tool for Kafka
# This module helps set up a burrow service that provides a
# http endpoint to query, and will email notifications on
# consumer groups statuses.
#
# == Parameters
# $client_id          - The client ID string to provide to Kafka when consuming
# $httpserver_port    - Port at which to make the burrow http endpoint available
# $lagcheck_intervals - Length of window of offsets used to monitor lag
#                       See: https://github.com/linkedin/Burrow/wiki/Configuration#lagcheck
# $zookeeper_hosts    - Array of zookeeper host urls
# $zookeeper_path     - The full path to the znode that is the root for the Kafka cluster
# $kafka_cluster_name - Name of the Kafka cluster
# $kafka_brokers      - Array of kafka broker urls
# $consumer_groups    - Consumer groups to be monitored to get email notifications
# $smtp_server        - SMTP server to send emails from
# $from_email         - From email address for notification
# $to_email           - Comma separated email addresses to send email notification to
# $email_template     - The name of the email template to use for Burrow's alerts

class burrow (
    $ensure = 'present',
    $client_id = 'burrow-client',
    $httpserver_port = 8000,
    $lagcheck_intervals = 10,
    $zookeeper_hosts,
    $zookeeper_path,
    $kafka_cluster_name,
    $kafka_brokers,
    $consumer_groups,
    $smtp_server,
    $from_email,
    $to_emails,
    $email_template = 'burrow/email.tmpl.erb'

)
{
    require_package('burrow')

    file { '/etc/burrow/burrow.cfg':
        ensure  => $ensure,
        content => template('burrow/burrow.cfg.erb'),
    }

    file { '/etc/burrow/email.tmpl':
        ensure  => $ensure,
        content => template($email_template),
    }

    service { 'burrow':
        ensure    => ensure_service($ensure),
        enable    => true,
        subscribe => File['/etc/burrow/burrow.cfg'],
    }
}
