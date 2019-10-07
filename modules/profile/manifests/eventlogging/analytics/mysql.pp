# == Class profile::eventlogging::analytics::mysql
#
# Consumes the mixed stream of events and writes them to MySQL
#
class profile::eventlogging::analytics::mysql(
    $mysql_consumers = hiera('profile::eventlogging::analytics::mysql::consumers'),
    $mysql_db        = hiera('profile::eventlogging::analytics::mysql::db', '127.0.0.1/log'),
    $statsd_host     = hiera('profile::eventlogging::analytics::mysql::statsd_host', 'statsd.eqiad.wmnet'),
    $ensure          = hiera('profile::eventlogging::analytics::mysql::ensure', 'present'),
) {

    include profile::eventlogging::analytics::server

    ## MySQL / MariaDB

    # Log strictly valid events to the 'log' database on m4-master.

    class { 'passwords::mysql::eventlogging': }    # T82265
    $mysql_user = $passwords::mysql::eventlogging::user
    $mysql_pass = $passwords::mysql::eventlogging::password

    $kafka_consumer_scheme = $profile::eventlogging::analytics::server::kafka_consumer_scheme
    $kafka_brokers_string  = $profile::eventlogging::analytics::server::kafka_brokers_string

    # Add more here as requested.
    $topics_to_consume = [
        # Valid eventlogging analytics events are all in this one topic.
        'eventlogging-valid-mixed',
    ]
    $topics_string = join($topics_to_consume, ',')
    $kafka_consumer_uri = "${kafka_consumer_scheme}/${kafka_brokers_string}?topics=${topics_string}"

    # Map function to use on events consumed by mysql. T179625
    $map_function      = '&function=mysql_mapper'

    # Custom URI scheme to pass events through map function
    $map_scheme        = 'map://'

    # Kafka consumer group for this consumer is mysql-m4-master
    eventlogging::service::consumer { $mysql_consumers:
        ensure => $ensure,
        # auto commit offsets to kafka more often for mysql consumer
        input  => "${map_scheme}${kafka_consumer_uri}&auto_commit_interval_ms=1000${map_function}",
        output => "mysql://${mysql_user}:${mysql_pass}@${mysql_db}?charset=utf8&statsd_host=${statsd_host}&replace=True",
        sid    => 'eventlogging_consumer_mysql_00',
        # Restrict permissions on this config file since it contains a password.
        owner  => 'root',
        group  => 'eventlogging',
        mode   => '0640',
    }
}
