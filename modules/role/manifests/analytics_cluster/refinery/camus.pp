# == Class role::analytics_cluster::refinery::camus
# Uses camus::job to set up cron jobs to
# import data from Kafka into Hadoop.
#
class role::analytics_cluster::refinery::camus {
    require role::analytics_cluster::refinery

    $kafka_config = kafka_config('analytics')

    # Make all uses of camus::job set default kafka_brokers and camus_jar.
    # If you build a new camus or refinery, and you want to use it, you'll
    # need to change these.  You can also override these defaults
    # for a particular camus::job instance by setting the parameter on
    # the camus::job declaration.
    Camus::Job {
        kafka_brokers => suffix($kafka_config['brokers']['array'], ':9092'),
        camus_jar     => "${role::analytics_cluster::refinery::path}/artifacts/org/wikimedia/analytics/camus-wmf/camus-wmf-0.1.0-wmf7.jar",
        check_jar     => "${role::analytics_cluster::refinery::path}/artifacts/org/wikimedia/analytics/refinery/refinery-camus-0.0.34.jar",
    }

    # Import webrequest_* topics into /wmf/data/raw/webrequest
    # every 10 minutes, check runs and flag fully imported hours.
    camus::job { 'webrequest':
        check  => true,
        minute => '*/10',
    }

    # Import eventlogging_* topics into /wmf/data/raw/eventlogging
    # once every hour.
    camus::job { 'eventlogging':
        minute => '5',
    }

    # Import eventbus topics into /wmf/data/raw/eventbus
    # once every hour.
    camus::job { 'eventbus':
        minute => '5',
    }

    # Import mediawiki_* topics into /wmf/data/raw/mediawiki
    # once every hour.  This data is expected to be Avro binary.
    camus::job { 'mediawiki':
        check   => true,
        minute  => '15',
        # refinery-camus contains some custom decoder classes which
        # are needed to import Avro binary data.
        libjars => "${role::analytics_cluster::refinery::path}/artifacts/org/wikimedia/analytics/refinery/refinery-camus-0.0.28.jar",
    }
}
