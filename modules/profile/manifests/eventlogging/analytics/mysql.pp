# == Class profile::eventlogging::analytics::mysql
#
# Consumes the mixed stream of events and writes them to MySQL
#
class profile::eventlogging::analytics::mysql(
    $mysql_consumers = hiera('profile::eventlogging::analytics::mysql::consumers'),
    $mysql_db        = hiera('profile::eventlogging::analytics::mysql::db', '127.0.0.1/log'),
    $statsd_host     = hiera('profile::eventlogging::analytics::mysql::statsd_host', 'statsd.eqiad.wmnet'),
) {

    include profile::eventlogging::analytics::server

    # We use the mediawiki/event-schemas to support insertion of events from EventBus
    # that use those schemas not on meta.wikimedia.org.
    # NOTE: If an event schema changes, the eventlogging-consumer process(es) will
    # not be automatically restarted.  You must manually restart this for the consumer
    # process to pick up changes to local schemas.
    class { '::eventschemas::mediawiki': }

    ## MySQL / MariaDB

    # Log strictly valid events to the 'log' database on m4-master.

    class { 'passwords::mysql::eventlogging': }    # T82265
    $mysql_user = $passwords::mysql::eventlogging::user
    $mysql_pass = $passwords::mysql::eventlogging::password

    $kafka_consumer_scheme = $profile::eventlogging::analytics::server::kafka_consumer_scheme
    $kafka_brokers_string  = $profile::eventlogging::analytics::server::kafka_brokers_string

    # Add more here as requested.
    # NOTE: The datacenter prefixed topics are produced via EventBus, and are of
    # schemas in the mediawiki/event-schemas repository.
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
        # auto commit offsets to kafka more often for mysql consumer
        input  => "${map_scheme}${kafka_consumer_uri}&auto_commit_interval_ms=1000${map_function}",
        output => "mysql://${mysql_user}:${mysql_pass}@${mysql_db}?charset=utf8&statsd_host=${statsd_host}&replace=True",
        sid    => 'eventlogging_consumer_mysql_00',
        # Restrict permissions on this config file since it contains a password.
        owner  => 'root',
        group  => 'eventlogging',
        mode   => '0640',
    }

    $eventbus_topics_to_consume = [
        # Various mediawiki events (via EventBus)
        'eqiad.mediawiki.page-create',
        'codfw.mediawiki.page-create',
        'eqiad.mediawiki.page-move',
        'codfw.mediawiki.page-move',
        'eqiad.mediawiki.page-delete',
        'codfw.mediawiki.page-delete',
        'eqiad.mediawiki.page-undelete',
        'codfw.mediawiki.page-undelete',
    ]
    $eventbus_topics_string = join($eventbus_topics_to_consume, ',')
    $kafka_consumer_uri_eventbus = "${kafka_consumer_scheme}/${kafka_brokers_string}?topics=${eventbus_topics_string}&auto_offset_reset=earliest"

    # Use a separate mysql consumer process to insert eventbus events.
    # The schemas for these types of events are managed differently, and we don't
    # want bugs in one to affect the other.
    eventlogging::service::consumer { 'mysql-eventbus':
        # auto commit offsets to kafka more often for mysql consumer
        input        => "${kafka_consumer_uri_eventbus}&auto_commit_interval_ms=1000",
        output       => "mysql://${mysql_user}:${mysql_pass}@${mysql_db}?charset=utf8&statsd_host=${statsd_host}&replace=True",
        # Load and cache local (EventBus) schemas so those events can be inserted into MySQL too.
        # This will require a restart of the consumer process(es) when there are any new schemas.
        schemas_path => "${::eventschemas::mediawiki::path}/jsonschema",
        sid          => 'eventlogging_consumer_mysql_eventbus_00',
        # Restrict permissions on this config file since it contains a password.
        owner        => 'root',
        group        => 'eventlogging',
        mode         => '0640',
        # The consumer will be reloaded (SIGHUPed, not restarted)
        # if any of these resources change.
        # Reload if mediawiki/event-schemas has a change.
        reload_on    =>  Class['::eventschemas'],
    }
}
