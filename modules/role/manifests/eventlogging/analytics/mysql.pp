
# == Class role::eventlogging::analytics::mysql
# Consumes the mixed stream of events and writes them to MySQL
#
class role::eventlogging::analytics::mysql {
    include role::eventlogging::analytics::server

    ## MySQL / MariaDB

    # Log strictly valid events to the 'log' database on m4-master.

    class { 'passwords::mysql::eventlogging': }    # T82265
    $mysql_user = $passwords::mysql::eventlogging::user
    $mysql_pass = $passwords::mysql::eventlogging::password
    $mysql_db = $::realm ? {
        production => 'm4-master.eqiad.wmnet/log',
        labs       => '127.0.0.1/log',
    }

    # Run N parallel mysql consumers processors.
    # These will auto balance amongst themselves.
    $mysql_consumers = hiera(
        'eventlogging_mysql_consumers',
        ['mysql-m4-master-00']
    )
    $kafka_consumer_group = 'eventlogging_consumer_mysql_00'

    # Where possible, if this is set, it will be included in client configuration
    # to avoid having to do API version for Kafka < 0.10 (where there is not a version API).
    $kafka_api_version         = $role::eventlogging::analytics::server::kafka_config['api_version']

    # Append this to query params if set.
    $kafka_api_version_param = $kafka_api_version ? {
        undef   => '',
        default => "&api_version=${kafka_api_version}"
    }

    # mixed_uri URI is defined for DRY purposes in role::eventlogging::analytics::server.
    $kafka_mixed_uri = $role::eventlogging::analytics::server::kafka_mixed_uri

    # Define statsd host url to send mysql insert metrics.
    # For beta cluster, set in https://wikitech.wikimedia.org/wiki/Hiera:Deployment-prep
    $statsd_host          = hiera('eventlogging_statsd_host', 'statsd.eqiad.wmnet')

    # Kafka consumer group for this consumer is mysql-m4-master
    eventlogging::service::consumer { $mysql_consumers:
        # auto commit offsets to kafka more often for mysql consumer
        input  => "${kafka_mixed_uri}&auto_commit_interval_ms=1000${$kafka_api_version_param}",
        output => "mysql://${mysql_user}:${mysql_pass}@${mysql_db}?charset=utf8&statsd_host=${statsd_host}&replace=True",
        sid    => $kafka_consumer_group,
        # Restrict permissions on this config file since it contains a password.
        owner  => 'root',
        group  => 'eventlogging',
        mode   => '0640',
    }
}
