# == Class role::eventlogging::analytics::mysql
# Consumes the mixed stream of events and writes them to MySQL
#
#
# filtertags: labs-project-deployment-prep
class role::eventlogging::analytics::mysql {
    include role::eventlogging::analytics::server

    # We use the mediawiki/event-schemas to support insertion of events from EventBus
    # that use those schemas not on meta.wikimedia.org.
    # NOTE: If an event schema changes, the eventlogging-consumer process(es) will
    # not be automatically restarted.  You must manually restart this for the consumer
    # process to pick up changes to local schemas.
    require eventschemas

    ## MySQL / MariaDB

    # Log strictly valid events to the 'log' database on m4-master.

    class { 'passwords::mysql::eventlogging': }    # T82265
    $mysql_user = $passwords::mysql::eventlogging::user
    $mysql_pass = $passwords::mysql::eventlogging::password
    $mysql_db = $::realm ? {
        production => 'm4-master.eqiad.wmnet/log',
        labs       => '127.0.0.1/log',
    }

    eventlogging::plugin { 'filters':
        source => 'puppet:///modules/eventlogging/filters.py',
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

    $kafka_consumer_scheme = $role::eventlogging::analytics::server::kafka_consumer_scheme
    $kafka_brokers_string  = $role::eventlogging::analytics::server::kafka_brokers_string

    # Add more here as requested.
    # NOTE: The datacenter prefixed topics are produced via EventBus, and are of
    # schemas in the mediawiki/event-schemas repository.
    $topics_to_consume = [
        # Valid eventlogging analytics events are all in this one topic.
        'eventlogging-valid-mixed',
        # Various mediawiki events (via EventBus)
        'eqiad.mediawiki.revision-create',
        'codfw.mediawiki.revision-create',
        'eqiad.mediawiki.page-move',
        'codfw.mediawiki.page-move',
        'eqiad.mediawiki.page-delete',
        'codfw.mediawiki.page-delete',
        'eqiad.mediawiki.page-undelete',
        'codfw.mediawiki.page-undelete',
    ]
    $topics_string = join($topics_to_consume, ',')
    $kafka_consumer_uri = "${kafka_consumer_scheme}/${kafka_brokers_string}?topics=${topics_string}"

    # Define statsd host url to send mysql insert metrics.
    # For beta cluster, set in https://wikitech.wikimedia.org/wiki/Hiera:Deployment-prep
    $statsd_host          = hiera('eventlogging_statsd_host', 'statsd.eqiad.wmnet')

    # Filtering function to use on events consumed by mysql
    $filter_function      = '&function=should_insert_event'

    # Custom URI scheme to pass events through filter
    $filter_scheme        = 'filter://'

    # Kafka consumer group for this consumer is mysql-m4-master
    eventlogging::service::consumer { $mysql_consumers:
        # auto commit offsets to kafka more often for mysql consumer
        input        => "${filter_scheme}${kafka_consumer_uri}&auto_commit_interval_ms=1000${$kafka_api_version_param}${filter_function}",
        output       => "mysql://${mysql_user}:${mysql_pass}@${mysql_db}?charset=utf8&statsd_host=${statsd_host}&replace=True",
        # Load and cache local (EventBus) schemas so those events can be inserted into MySQL too.
        # This will require a restart of the consumer process(es) when there are any new schemas.
        schemas_path => "${::eventschemas::path}/jsonschema",
        sid          => $kafka_consumer_group,
        # Restrict permissions on this config file since it contains a password.
        owner        => 'root',
        group        => 'eventlogging',
        mode         => '0640',

    }
}
